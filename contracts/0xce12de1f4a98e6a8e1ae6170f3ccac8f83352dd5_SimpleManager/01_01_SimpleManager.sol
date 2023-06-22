// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.19;

interface ISimpleFarm {

    function setRewardRate(
        uint256 newRate
    )
        external;

    function rewardToken()
        external
        view
        returns (IERC20);

    function rewardDuration()
        external
        view
        returns (uint256);
}

interface IERC20 {

    function transfer(
        address to,
        uint256 amount
    )
        external
        returns (bool);

    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool);
}

contract SimpleManager {

    address public owner;
    address public worker;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "SimpleManager: NOT_OWNER"
        );
        _;
    }

    modifier onlyWorker() {
        require(
            msg.sender == worker,
            "SimpleManager: NOT_WORKER"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
        worker = msg.sender;
    }

    function changeWorker(
        address _newWorker
    )
        external
        onlyOwner
    {
        worker = _newWorker;
    }

    function updateRatesF2(
        address _targetFarm1,
        uint256 _newRate1,
        address _targetFarm2,
        uint256 _newRate2
    )
        external
        onlyWorker
    {
        address[] memory farms = new address[](2);
        uint256[] memory rates = new uint256[](2);

        farms[0] = _targetFarm1;
        farms[1] = _targetFarm2;

        rates[0] = _newRate1;
        rates[1] = _newRate2;

        _manageRates(
            farms,
            rates
        );
    }

    function updateRatesF3(
        address _targetFarm1,
        uint256 _newRate1,
        address _targetFarm2,
        uint256 _newRate2,
        address _targetFarm3,
        uint256 _newRate3
    )
        external
        onlyWorker
    {
        address[] memory farms = new address[](3);
        uint256[] memory rates = new uint256[](3);

        farms[0] = _targetFarm1;
        farms[1] = _targetFarm2;
        farms[2] = _targetFarm3;

        rates[0] = _newRate1;
        rates[1] = _newRate2;
        rates[2] = _newRate3;

        _manageRates(
            farms,
            rates
        );
    }

    function updateRatesF4(
        address _targetFarm1,
        uint256 _newRate1,
        address _targetFarm2,
        uint256 _newRate2,
        address _targetFarm3,
        uint256 _newRate3,
        address _targetFarm4,
        uint256 _newRate4
    )
        external
        onlyWorker
    {
        address[] memory farms = new address[](4);
        uint256[] memory rates = new uint256[](4);

        farms[0] = _targetFarm1;
        farms[1] = _targetFarm2;
        farms[2] = _targetFarm3;
        farms[3] = _targetFarm4;

        rates[0] = _newRate1;
        rates[1] = _newRate2;
        rates[2] = _newRate3;
        rates[3] = _newRate4;

        _manageRates(
            farms,
            rates
        );
    }

    function updateRatesF5(
        address _targetFarm1,
        uint256 _newRate1,
        address _targetFarm2,
        uint256 _newRate2,
        address _targetFarm3,
        uint256 _newRate3,
        address _targetFarm4,
        uint256 _newRate4,
        address _targetFarm5,
        uint256 _newRate5
    )
        external
        onlyWorker
    {
        address[] memory farms = new address[](5);
        uint256[] memory rates = new uint256[](5);

        farms[0] = _targetFarm1;
        farms[1] = _targetFarm2;
        farms[2] = _targetFarm3;
        farms[3] = _targetFarm4;
        farms[4] = _targetFarm5;

        rates[0] = _newRate1;
        rates[1] = _newRate2;
        rates[2] = _newRate3;
        rates[3] = _newRate4;
        rates[4] = _newRate5;

        _manageRates(
            farms,
            rates
        );
    }

    function manageRates(
        address[] memory _targetFarms,
        uint256[] memory _newRates
    )
        external
        onlyWorker
    {
        _manageRates(
            _targetFarms,
            _newRates
        );
    }

    function _manageRates(
        address[] memory _targetFarms,
        uint256[] memory _newRates
    )
        internal
    {
        for (uint256 i = 0; i < _targetFarms.length; i++) {

            ISimpleFarm farm = ISimpleFarm(
                _targetFarms[i]
            );

            IERC20 rewardToken = farm.rewardToken();
            uint256 rewardDuration = farm.rewardDuration();

            rewardToken.approve(
                _targetFarms[i],
                _newRates[i] * rewardDuration
            );

            farm.setRewardRate(
                _newRates[i]
            );
        }
    }

    function recoverToken(
        IERC20 tokenAddress,
        uint256 tokenAmount
    )
        external
    {
        tokenAddress.transfer(
            owner,
            tokenAmount
        );
    }
}