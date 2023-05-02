pragma solidity ^0.8.11;

import "communal/Owned.sol";

//An oracle that provides prices for different LSDs
//NOTE: This is the rate quoted by the LSDs contracts, no pricing of market impact and liquidity risk is calculated
contract Darknet is Owned {
    mapping(address => bytes4) public router; //connects LSD address to marketAddress
    //need to store 1. function signature 2. conversion (if any)

    address public constant wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /* ============ Constructor ============ */
    constructor(address _owner, address[] memory _lsds, bytes4[] memory _links) Owned(_owner) {
        require(_lsds.length == _links.length, "Array length mismatch");
        for (uint256 i = 0; i < _lsds.length; i++) {
            router[_lsds[i]] = _links[i];
        }
    }

    event RouterAdded(address lsd, bytes4 link);

    function checkPrice(address lsd) public view returns (uint256) {
        if (lsd == wethAddress) return 1e18;

        bytes4 fn_sig = router[lsd];
        (bool success, bytes memory response) = lsd.staticcall(abi.encodePacked(fn_sig));
        require(success, "Static call failed");
        uint256 price = abi.decode(response, (uint256));
        return price;
    }

    function addRouter(address _lsd, bytes4 _link) external onlyOwner {
        require(router[_lsd] == bytes4(0), "Router already exists");
        router[_lsd] = _link;
        emit RouterAdded(_lsd, _link);
    }
}