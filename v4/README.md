# CATLAS v4

v3에서 확인한 UMAP·violin 표시 문제와 발현 기준값 동작을 수정한 버전입니다. 기존 v3 파일과 원본 RDS는 수정하거나 덮어쓰지 않았습니다.

| 항목 | v3 원인 | v4 변경 |
| --- | --- | --- |
| Expression UMAP의 색상 범례 겹침 | 각 조건 패널이 같은 기본 위치에 별도 colorbar를 생성했습니다. 발현 색상 범위도 패널별로 결정됐습니다. | 모든 조건이 하나의 colorbar와 공통 발현 색상 범위를 사용합니다. |
| Normal 제목 누락 | 패널별 `layout(title=...)`이 `subplot()`에서 하나의 전체 제목으로 합쳐졌습니다. | 각 패널 위에 Normal·Tumor 제목을 개별 배치합니다. |
| Normal·Tumor violin 사이 간격 없음 | 양쪽 반쪽 violin이 같은 범주 중심을 사용했습니다. | 중심을 좌우로 조금 이동해 작은 간격을 두고, cell type 이름은 중앙에 유지합니다. |
| Cell-type 범례의 작은 점 | 실제 UMAP 점과 범례 점이 모두 크기 3을 사용했습니다. | 실제 점은 3으로 유지하고 범례 점은 6으로 키웁니다. 범례는 cell type당 하나이며 클릭하면 양쪽 패널의 해당 그룹이 함께 전환됩니다. |
| 기준값 슬라이더를 움직여도 그림 변화 없음 | 기준값을 양성 비율 안내와 요약 계산에만 사용하고 UMAP·violin에는 전달하지 않았습니다. | 기준값에 따라 UMAP 회색 표시와 violin 기준선이 즉시 갱신됩니다. |

양성 발현은 **`expression > threshold`**입니다. 기준값과 같은 세포도 포함하여 **`expression <= threshold`인 세포는 UMAP에서 회색**으로 표시합니다. Expression 모드와 Group 모드에 모두 적용되며, 기준값을 초과한 세포만 해당 모드의 색상을 사용합니다.

Violin에는 현재 기준값을 가로 점선으로 표시합니다. 기준값을 움직여도 세포를 제거하지 않으므로 violin 분포, 요약의 전체 세포 수 `n_cells`, 평균·중앙값의 계산 대상은 유지됩니다. 요약 표와 CSV에는 양성 세포 수 `n_positive`와 적용 기준값 `threshold`를 추가했습니다. `pct_pos`는 `100 × n_positive / n_cells`입니다.

슬라이더의 최댓값은 선택한 유전자의 최대 발현량에 맞춰 0.1 단위로 올림하며, 최소 3을 유지합니다. 유전자를 바꿨을 때 기존 기준값이 새 범위 안에 있으면 유지합니다. Condition 또는 Cell type을 모두 해제하면 선택된 세포가 없다는 안내를 표시합니다. 선택 사항인 Sub-type과 Sample은 비워 두면 해당 필터를 적용하지 않습니다.

앱은 `/home/minwook/Shiny_CRC_atlas/Catlas/v4/app.R`이며, UMAP과 violin 함수는 각각 `R/umap.R`, `R/violin.R`에 있습니다. 데이터는 `/home/minwook/Shiny_CRC_atlas/crc_shiny_app_seurat.rds`를 읽기 전용으로 사용합니다. 실행 스크립트는 `start_catlas_v4.sh`입니다.

실행 스크립트의 기본 주소는 `127.0.0.1:4510`입니다. 현재 운영 서비스는 여전히 v3로 실행되며 4510 포트를 사용하므로, v4 미리보기는 별도 포트로 실행합니다.

```bash
CATLAS_PORT=4511 /home/minwook/Shiny_CRC_atlas/Catlas/v4/start_catlas_v4.sh
```

서버 내 접속 주소는 `http://127.0.0.1:4511`입니다. 실행 중인 v3와 같은 4510 포트에 두 번째 앱을 실행하지 마세요. 운영 systemd 서비스의 실행 경로와 Apache 설정은 변경하지 않았습니다.

검증 명령은 다음과 같습니다.

```bash
/home/minwook/miniconda3/envs/crc_shiny/bin/Rscript /home/minwook/Shiny_CRC_atlas/Catlas/v4/tests/run_checks.R
```

54개 합성 데이터 검사가 통과했습니다. 검사는 Plotly에 전달되는 패널 제목·공통 색상 범위·범례 크기·회색 세포 수·violin 간격·기준선과 실제 Shiny 반응형 기준값/요약 갱신을 확인하며, RDS를 읽거나 서비스를 시작하지 않습니다. 양성 세포가 하나만 있을 때도 발현 색상을 JSON 배열로 유지하여 colorbar가 사라지지 않도록 검사합니다. 별도로 실제 RDS를 읽어 98,428개 세포로 앱 초기화가 완료되는 것도 확인했습니다.

Firefox에서 양쪽 패널 제목, 양성 세포가 하나일 때를 포함한 단일 colorbar, 지름 6인 범례 점과 양쪽 패널의 그룹 전환, violin 간격과 기준선을 확인했습니다. 검사 서버의 헤드리스 브라우저는 WebGL을 지원하지 않아 UMAP 점의 색상 시각 검사는 진단용 화면에서만 SVG로 대체하여 진행했습니다. 실제 앱은 `scattergl`을 유지합니다.
