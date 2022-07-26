// SPDX-License-Identifier: MIT

/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";

interface ICurveBasePool {
    function initialize(
        address _config,
        uint256[] calldata _precisionIndent,
        address[] calldata _tokens,
        address _curveSwap,
        address _zap,
        uint256[][] calldata _corrspondedCoins
    ) external;
}

interface ICurveMetaPool {
    function initialize(
        address _config,
        uint256[] calldata _precisionIndent,
        address[] calldata _tokens,
        address _baseSwap,
        address _curveSwap,
        address _curveZap,
        address _baseToken,
        bool _isV2, // tusd,frax,busdv2,alusd,mim
        uint256[][] calldata _corrspondedCoins
    ) external;
}

contract CurvePoolFactory {
    address public owner;
    address public config;

    struct Data {
        uint256 tag;
        address pool;
    }

    uint256 public index;

    mapping(uint256 => Data) public pools;

    event CreatePool(address newClone);

    constructor(address _owner, address _config) {
        owner = _owner;
        config = _config;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "CurvePoolFactory: !authorized");

        owner = _owner;
    }

    function createBasePool(
        address _master,
        uint256[] calldata _precisionIndent,
        address[] calldata _tokens,
        address _curveSwap,
        address _zap,
        uint256[][] calldata _corrspondedCoins
    ) external returns (address) {
        require(msg.sender == owner, "CurvePoolFactory: !authorized");

        address instance = Clones.clone(address(_master));

        ICurveBasePool(instance).initialize(config, _precisionIndent, _tokens, _curveSwap, _zap, _corrspondedCoins);

        emit CreatePool(instance);

        pools[++index] = Data(0, instance);

        return instance;
    }

    function createMetaPool(
        address _master,
        uint256[] calldata _precisionIndent,
        address[] calldata _tokens,
        address _baseSwap,
        address _curveSwap,
        address _curveZap,
        address _baseToken,
        bool _isV2, // tusd,frax,busdv2,alusd,mim
        uint256[][] calldata _corrspondedCoins
    ) external returns (address) {
        require(msg.sender == owner, "CurvePoolFactory: !authorized");

        address instance = Clones.clone(address(_master));

        ICurveMetaPool(instance).initialize(
            config,
            _precisionIndent,
            _tokens,
            _baseSwap,
            _curveSwap,
            _curveZap,
            _baseToken,
            _isV2, // tusd,frax,busdv2,alusd,mim
            _corrspondedCoins
        );

        emit CreatePool(instance);

        pools[++index] = Data(1, instance);

        return instance;
    }
}