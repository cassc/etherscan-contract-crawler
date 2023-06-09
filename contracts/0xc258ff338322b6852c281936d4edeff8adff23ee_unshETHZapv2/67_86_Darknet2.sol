pragma solidity ^0.8.18;



contract Darknet2 {
    mapping(address => bytes4) public router;
    mapping(address => bool) private hasArgs;
    address public constant wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /* ============ Constructor ============ */
    constructor(
        address[] memory _lsds,
        bytes4[] memory _links,
        bool[] memory _hasArgs
    ) {
        require(_lsds.length == _links.length && _lsds.length == _hasArgs.length, "Array length mismatch");
        for (uint256 i = 0; i < _lsds.length; i++) {
            router[_lsds[i]] = _links[i];
            if (_hasArgs[i]) {
                hasArgs[_lsds[i]] = true;
            }
        }
    }

    function checkPrice(address lsd) public view returns (uint256) {
        if(lsd == wethAddress) {
            return 1e18;
        }

        bytes4 fn_sig = router[lsd];
        bool success;
        bytes memory response;
        if (hasArgs[lsd]) {
            (success, response) = lsd.staticcall(abi.encodePacked(fn_sig, uint256(1e18)));
        } else {
            (success, response) = lsd.staticcall(abi.encodePacked(fn_sig));
        }
        require(success, "Static call failed");
        uint256 price = abi.decode(response, (uint256));
        return price;
    }

}