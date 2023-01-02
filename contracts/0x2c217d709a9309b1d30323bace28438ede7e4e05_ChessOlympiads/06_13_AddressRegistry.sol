// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

abstract contract AddressRegistry {
    address payable immutable WETH_9;
    address public immutable KP3R_V1;
    address public immutable KP3R_LP;
    address public immutable SWAP_ROUTER;
    address public immutable KEEP3R;
    address public immutable SUDOSWAP_FACTORY;
    address public immutable SUDOSWAP_CURVE;

    constructor() {
        address _weth;
        address _kp3rV1;
        address _kp3rLP;
        address _keep3r;
        address _uniswapRouter;
        address _sudoswapFactory;
        address _sudoswapCurve;

        uint256 _chainId = block.chainid;
        if (_chainId == 1 || _chainId == 31337) {
            _weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            _kp3rV1 = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;
            _kp3rLP = 0x3f6740b5898c5D3650ec6eAce9a649Ac791e44D7;
            _keep3r = 0xeb02addCfD8B773A5FFA6B9d1FE99c566f8c44CC;
            _uniswapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
            _sudoswapFactory = 0xb16c1342E617A5B6E4b631EB114483FDB289c0A4;
            _sudoswapCurve = 0x7942E264e21C5e6CbBA45fe50785a15D3BEb1DA0;
        } else if (_chainId == 5) {
            _weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
            _kp3rV1 = 0x16F63C5036d3F48A239358656a8f123eCE85789C;
            _kp3rLP = 0xb4A7137B024d4C0531b0164fCb6E8fc20e6777Ae;
            _keep3r = 0x229d018065019c3164B899F4B9c2d4ffEae9B92b;
            _uniswapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
            _sudoswapFactory = 0xF0202E9267930aE942F0667dC6d805057328F6dC;
            _sudoswapCurve = 0x02363a2F1B2c2C5815cb6893Aa27861BE0c4F760;
        }

        WETH_9 = payable(_weth);
        KP3R_V1 = _kp3rV1;
        KP3R_LP = _kp3rLP;
        KEEP3R = _keep3r;
        SWAP_ROUTER = _uniswapRouter;
        SUDOSWAP_FACTORY = _sudoswapFactory;
        SUDOSWAP_CURVE = _sudoswapCurve;
    }
}