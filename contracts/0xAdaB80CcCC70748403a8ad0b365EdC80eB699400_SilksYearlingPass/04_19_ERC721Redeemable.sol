// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract RedeemContract {
    function extMint(address to, uint256 amount_req) external virtual;
}


contract ERC721Redeemable is ERC721Enumerable, Ownable, Pausable {
    using Address for address;
    
    bool public redeemStarted;
    address public redeemAddress;
    string public baseUri;
    address public payee;
    uint256 public maxSupply;
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _payee,
        uint256 _maxSupply
    ) ERC721 (_name, _symbol) {
        payee = _payee;
        maxSupply = _maxSupply;
        _pause();
    }
    
    function redeem(
        uint256[] calldata _passIds
    )
    external
    {
        require(redeemStarted, "REDEEM_PAUSED");
        require(Address.isContract(redeemAddress), "INVALID_ADDRESS");
        for (uint256 i = 0; i < _passIds.length; i++) {
            require(ownerOf(_passIds[i]) == msg.sender, "NOT_PASS_OWNER");
            _burn(_passIds[i]);
        }
        // Call contract to mint horses to msg.sender
        RedeemContract(redeemAddress).extMint(msg.sender, _passIds.length);
    }
    
    function setRedeemInfo(
        address _redeemContractAddress,
        bool _redeemStarted
    )
    external
    onlyOwner
    {
        redeemAddress = _redeemContractAddress;
        redeemStarted = _redeemStarted;
    }
    
    function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory) {
        return string(
            abi.encodePacked(baseUri, '/')
        );
    }
    
    function setBaseUri(
        string calldata _baseUri
    )
    public
    onlyOwner
    {
        baseUri = _baseUri;
    }
    
    function withdrawFunds()
    external
    onlyOwner
    {
        sendEth(payee, address(this).balance);
    }
    
    function setPayeeAddress(
        address _payee
    )
    external
    onlyOwner
    {
        payee = _payee;
    }
    
    function sendEth(
        address to,
        uint amount
    )
    internal
    {
        require(to != address(0), "INVALID_PAYMENT_ADDRESS");
        (bool success,) = to.call{value : amount}("");
        require(success, "Failed to send ether");
    }
    
    function pause()
    public
    onlyOwner
    {
        _pause();
    }
    
    function unpause()
    public
    onlyOwner
    {
        _unpause();
    }
    
    function setMaxSupply(
        uint256 _maxSupply
    )
    external
    onlyOwner
    {
        maxSupply = _maxSupply;
    }
}