// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NomadReward is ERC1155, AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    string private _contractURI;
    address private _redeemAddress;

    constructor() ERC1155("") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
    }

    function setURI(string memory newUri) public onlyRole(OPERATOR_ROLE) {
        _setURI(newUri);
    }

    function setRedeemAddress(address redeemAddress)
    public
    onlyRole(OPERATOR_ROLE)
    {
        _redeemAddress = redeemAddress;
    }

    function getRedeemAddress()
    public
    view
    returns (address)
    {
        return _redeemAddress;
    }


    ///@dev Sets the contract URI for OpenSea
    ///@param newContractURI The new URI for the contract
    function setContractURI(string memory newContractURI)
    external
    onlyRole(OPERATOR_ROLE)
    {
        _contractURI = newContractURI;
    }

    ///Returns the contract URI for OpenSea
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) external {
        require(
            _redeemAddress != address(0) && msg.sender == _redeemAddress,
            "INVALID_REDEEM_ADDRESS"
        );
        _mint(account, id, amount, "");
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(OPERATOR_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}