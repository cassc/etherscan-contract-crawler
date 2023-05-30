// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity >=0.4.25;

/**
 * @dev Contract type mapping.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
contract Type {
    uint256 constant PRIME = 1; // Prime/master/build/PrimeToken.abi happ=suggestions features=erc20,suggestions
    uint256 constant PRIDE = 2; // Pride/build/PrideToken.abi features=erc20
    uint256 constant FOOD_COIN = 3; // Prime/foodcoin/build/FoodCoin.abi features=erc20
    uint256 constant EGO = 4; // OldEgoCoin/master/build/EgoCoin.abi happ=suggestions features=erc20
    uint256 constant EGO_TIME_BASED = 5;  // OldEgoCoin/time-based/build/EgoCoin.abi happ=suggestions features=erc20
    uint256 constant EGO_TRAINER_TOKEN = 6;  // OldEgoCoin/trainer-token/build/TrainerToken.abi features=erc20
    uint256 constant DAICO = 7; // Daico/build/Daico.abi happ=daico features=daico
    uint256 constant ITEM_DROPS = 8; // ItemDrops/build/ItemDrops.abi happ=lotto features=lotto
    uint256 constant ITEM_TOKEN = 9; // ItemDrops/build/ItemToken.abi features=erc20
    uint256 constant COMMUNITY = 10; // Community/build/CommunityToken.abi happ=suggestions features=erc20,suggestions,proposals
    uint256 constant PAYMENT_RELAY = 11; // PaymentRelay/build/PaymentRelay.abi
    uint256 constant GHOST = 12; // Ghost/build/GhostToken.abi features=erc20
    uint256 constant FORUM = 13;  // Forum/build/ForumToken.abi happ=nft features=erc721,suggestions,proposals
    uint256 constant BOOK = 14;  //Book/build/BaseBook.abi happ=book features=book
    uint256 constant VOTING_BOOK = 15;  //Book/build/VotingBook.abi happ=book
    uint256 constant REFUNDS = 16;  //Refund/build/Refunds.abi happ=refunds features=refunds
    uint256 constant SMART_LICENSE = 17;  //SmartLicense/build/SmartLicense.abi happ=smart features=smart-license
    uint256 constant FIRE = 18;  //OldFire/standard/build/FireToken.abi features=erc20
    uint256 constant CORE = 19;  //Core/build/CoreToken.abi happ=core features=erc20,suggestions,core
    uint256 constant CORE_TASKS_EXTENSION = 20;  //Core/build/TasksExtension.abi happ=core
    uint256 constant PRICES = 21;  //Prices/build/Prices.abi
    uint256 constant CORE_TASKS_LIBRARY = 22; //Core/build/TasksLibrary.abi
    uint256 constant CORE_FREELANCE_EXTENSION = 23; //Core/build/FreelanceExtension.abi happ=core
    uint256 constant CORE_FREELANCE_LIBRARY = 24; //Core/build/FreelanceLibrary.abi
    uint256 constant HOURGLASS = 25; //Hourglass/build/Hourglass.abi happ=hourglass features=erc20,hourglass
    uint256 constant NFT = 26; //Nft/build/NfToken.abi happ=nft features=erc721
    uint256 constant PARTIAL_NFT = 27; //Nft/build/PartialNft.abi happ=nft features=erc721
    uint256 constant FUEL = 28; //Fuel/build/FuelToken.abi features=erc20,stake
    uint256 constant SWAPPER = 29; //Swapper/build/Swapper.abi features=swapper
    uint256 constant SWAP_RELAY = 30; //Prime/master/build/SwapRelay.abi
    uint256 constant NFT_ITEM_POOL = 31; //ItemDrops/build/NftItemPool.abi features=item-pool
    uint256 constant SWAP_RELAY_V1 = 32; //Prime/master/build/SwapRelayV1.abi
    uint256 constant SMART_RELAY = 33; //SmartLicense/build/SmartRelay.abi features=smart-relay
    uint256 constant SWAP_NFT_RELAY = 34; //Nft/build/SwapNftRelay.abi features=nft-swap
    uint256 constant GAME_NFT = 35; //Nft/build/GameNft.abi features=erc721

    uint256 constant PRIME_DEPLOYER = 50;  //Prime/master/build/PrimeDeployer.abi features=deployer
    uint256 constant DAICO_DEPLOYER = 51;  //Daico/build/DaicoDeployer.abi features=deployer
    uint256 constant PRIME_GIVER = 52;  //Prime/master/build/PrimeGiver.abi
    uint256 constant FORUM_DEPLOYER = 53;  //Forum/build/ForumDeployer.abi features=deployer
    uint256 constant COMMUNITY_DEPLOYER = 54;  //Community/build/CommunityDeployer.abi features=deployer
    uint256 constant ITEM_DROPS_DEPLOYER = 55;  //ItemDrops/build/ItemDropsDeployer.abi features=deployer
    uint256 constant BOOK_DEPLOYER = 56;  //Book/build/BookDeployer.abi features=deployer
    uint256 constant SMART_LICENSE_DEPLOYER = 57;  //SmartLicense/build/SmartLicenseDeployer.abi features=deployer
    uint256 constant HOURGLASS_DEPLOYER = 58;  //Hourglass/build/HourglassDeployer.abi features=deployer
    uint256 constant NFT_DEPLOYER = 59;  //Nft/build/NftDeployer.abi features=deployer

    uint256 constant PROXY_TOKEN = 100;  //Proxy/build/ProxyToken.abi features=erc20
    uint256 constant PROXY_TOKEN_DEPLOYER = 101;  //Proxy/build/ProxyTokenDeployer.abi features=deployer
    uint256 constant PROXY_DEPLOYER = 102;  //Proxy/build/ProxyDeployer.abi features=deployer
    uint256 constant PROXY_SWAPPER = 103;  //Proxy/build/ProxySwapper.abi
    uint256 constant CROSSCHAIN_TOKEN = 104;  //Crosschain/build/CrosschainToken.abi features=erc20
    uint256 constant CROSSCHAIN_DEPLOYER = 105;  //Crosschain/build/CrosschainDeployer.abi features=deployer
    uint256 constant REFUNDS_DEPLOYER = 106;  //Refund/build/RefundsDeployer.abi features=deployer
    uint256 constant SWAPPER_DEPLOYER = 107;  //Swapper/build/SwapperDeployer.abi features=deployer

    uint256 constant RESERVED1 = 1001;

    uint256 public bwtype;
    uint256 public bwver;
}