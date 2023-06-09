// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface IKEI {

    event Upgrade(bytes32 indexed hash, string version, bytes snapshot);

    struct Core {
        address debt;
        address token;
        address oracle;
        address pricing;
        address rewards;
        address treasury;
    }

    struct Services {
        address pairs;
        address admin;
        address staking;
        address supplier;
        address identity;
        address referral;
        address liquidity;
        address affiliate;
        address processor;
    }

    struct Snapshot {
        address master;

        address debt;
        address token;
        address oracle;
        address pricing;
        address rewards;
        address treasury;

        address pairs;
        address admin;
        address staking;
        address supplier;
        address identity;
        address referral;
        address liquidity;
        address affiliate;
        address processor;
    }

    function WETH() external view returns (address);

    function master() external view returns (address);

    function token() external view returns (address);
    function rewards() external view returns (address);
    function treasury() external view returns (address);

    function debt() external view returns (address);
    function pairs() external view returns (address);
    function admin() external view returns (address);
    function oracle() external view returns (address);
    function pricing() external view returns (address);
    function staking() external view returns (address);
    function identity() external view returns (address);
    function supplier() external view returns (address);
    function referral() external view returns (address);
    function affiliate() external view returns (address);
    function liquidity() external view returns (address);
    function processor() external view returns (address);

    function version() external view returns (string memory);

    function upgrade(string memory newVersion) external;

    function snapshot() external view returns (Snapshot memory snapshot_);
    function snapshotHash() external view returns (bytes32);
    function core() external view returns (Core memory core_);
    function coreHash() external view returns (bytes32);
    function services() external view returns (Services memory core_);
    function servicesHash() external view returns (bytes32);
}