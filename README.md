# Gold Collateral Manager

![img-nft-005g](https://github.com/CrederLabs/Gold-Collateral-Manager/assets/34641838/3b235317-a1ca-4b89-8c69-cadfb3997a25)

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```

## Deploy

```
$ yarn deploy:baobab
$ yarn deploy:cypress
```

## Contracts

1. Baobab: ~~0xaD49d305143fD7A67511bb77Ba7E9650652340Da (NFT transfer disable 버전 적용. Repay KLAY 수수료 0.1%로 수정)~~ (Deprecated)
2. Baobab: 0x6393F1277FDb7afDb824b6986BC9146523D5F2F8 (NFT transfer 다시 허용 버전 적용)
2. Cypress GPC Test D: 0x547FADFF849B9f840ea7A01d13603b77C9cA2381 
3. Cypress(정식): 0x27397bFbeFD58A437f2636f80A8e70cFc363d4Ff

## 새 GoldType 등록 방법

1. e금 종류 표(https://github.com/CrederLabs/korea-gold-exchange-nft)의 GoldType을 확인하고, uri 정보를 ipfs에 업로드 한다.
2. ipfs 정보와 함께 민팅 정보를 TMC API 서버에 등록한다.
3. GoldCollateralManager(GPC) 컨트랙트의 registerCollateralExchangeAmount, registerRepaymentFeeAmount 정보를 등록한다.

## Audit Report

- [SlowMist Audit Report - GoldCollateralManager](https://github.com/CrederLabs/audit/blob/main/GoldCollateralManager/SlowMist%20Audit%20Report%20-%20GoldCollateralManager.pdf)

## Creder's Services and Community

- [Official Website](https://www.creder.biz)
- [The Mining Club](https://theminingclub.io)
- [Medium](https://medium.com/@creder2022)
- [Twitter](https://twitter.com/creder_official)
- [Telegram](https://t.me/creder_tg)
- [Discord](https://discord.com/invite/dR6FD4BYNk)