// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
import "./BaseController.sol";

/**
 * Register an DID name by pay ETH only once.
 */
contract ETHController is BaseController {
    // pay register fee as eth:
    uint128 public fee = 0.001 ether;

    constructor(address _registry) BaseController(_registry) {}

    function setEthRegisterFee(uint128 _fee) external onlyOwner {
        fee = _fee;
    }

    // register by ETH:

    function register(string memory name) external payable {
        registerFor(name, msg.sender);
    }

    // register for target address:

    function batchRegisterFor(
        string[] calldata names,
        address[] calldata registrants
    ) public payable {
        uint256 maxLength = names.length;
        require(maxLength == registrants.length, "invalid length");
        require(msg.value == fee * maxLength, "invalid register fee");
        uint256 i;
        uint256 tokenId;
        uint256 len;
        for (i = 0; i < maxLength; i++) {
            string memory name = names[i];
            address registrant = registrants[i];
            (tokenId, len) = registry.register(name, registrant);
            require(len >= 4, "invalid name length");
        }
    }

    function registerFor(string memory name, address registrant)
        public
        payable
    {
        require(msg.value == fee, "invalid register fee");
        uint256 tokenId;
        uint256 len;
        (tokenId, len) = registry.register(name, registrant);
        require(len >= 4, "invalid name length");
        bindAvatar(tokenId, registrant);
    }

    function withdraw(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }
}