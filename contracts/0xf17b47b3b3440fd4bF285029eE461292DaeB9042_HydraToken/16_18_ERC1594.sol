pragma solidity 0.5.4;

import "../token/ERC20Redeemable.sol";
import "../interfaces/IERC1594.sol";
import "../interfaces/IHasIssuership.sol";
import "../interfaces/IModerator.sol";
import "../roles/IssuerRole.sol";
import "../compliance/Moderated.sol";


contract ERC1594 is IERC1594, IHasIssuership, Moderated, ERC20Redeemable, IssuerRole {
    bool public isIssuable = true;

    event Issued(address indexed operator, address indexed to, uint256 value, bytes data);
    event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data);
    event IssuershipTransferred(address indexed from, address indexed to);
    event IssuanceFinished();

    /**
    * @notice Modifier to check token issuance status
    */
    modifier whenIssuable() {
        require(isIssuable, "Issuance period has ended.");
        _;
    }

    /**
     * @notice Transfer the token's singleton Issuer role to another address.
     */
    function transferIssuership(address _newIssuer) public whenIssuable onlyIssuer {
        require(_newIssuer != address(0), "New Issuer cannot be zero address.");
        require(msg.sender != _newIssuer, "New Issuer cannot have the same address as the old issuer.");
        _addIssuer(_newIssuer);
        _removeIssuer(msg.sender);
        emit IssuershipTransferred(msg.sender, _newIssuer);
    }

    /**
     * @notice End token issuance period permanently.
     */
    function finishIssuance() public whenIssuable onlyIssuer {
        isIssuable = false;
        emit IssuanceFinished();
    }

    function issue(address _tokenHolder, uint256 _value, bytes memory _data) public whenIssuable onlyIssuer {
        bool allowed;
        (allowed, , ) = moderator.verifyIssue(_tokenHolder, _value, _data);
        require(allowed, "Issue is not allowed.");
        _mint(_tokenHolder, _value);
        emit Issued(msg.sender, _tokenHolder, _value, _data);
    }

    function redeem(uint256 _value, bytes memory _data) public {
        bool allowed;
        (allowed, , ) = moderator.verifyRedeem(msg.sender, _value, _data);
        require(allowed, "Redeem is not allowed.");

        _burn(msg.sender, _value);
        emit Redeemed(msg.sender, msg.sender, _value, _data);
    }

    function redeemFrom(address _tokenHolder, uint256 _value, bytes memory _data) public {
        bool allowed;
        (allowed, , ) = moderator.verifyRedeemFrom(msg.sender, _tokenHolder, _value, _data);
        require(allowed, "RedeemFrom is not allowed.");

        _burnFrom(_tokenHolder, _value);
        emit Redeemed(msg.sender, _tokenHolder, _value, _data);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        bool allowed;
        (allowed, , ) = canTransfer(_to, _value, "");
        require(allowed, "Transfer is not allowed.");

        success = super.transfer(_to, _value);
    }

    function transferWithData(address _to, uint256 _value, bytes memory _data) public {
        bool allowed;
        (allowed, , ) = canTransfer(_to, _value, _data);
        require(allowed, "Transfer is not allowed.");

        require(super.transfer(_to, _value), "Transfer failed.");
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        bool allowed;
        (allowed, , ) = canTransferFrom(_from, _to, _value, "");
        require(allowed, "TransferFrom is not allowed.");

        success = super.transferFrom(_from, _to, _value);
    }    

    function transferFromWithData(address _from, address _to, uint256 _value, bytes memory _data) public {
        bool allowed;
        (allowed, , ) = canTransferFrom(_from, _to, _value, _data);
        require(allowed, "TransferFrom is not allowed.");

        require(super.transferFrom(_from, _to, _value), "TransferFrom failed.");
    }

    function canTransfer(address _to, uint256 _value, bytes memory _data) public view 
        returns (bool success, byte statusCode, bytes32 applicationCode) 
    {
        return moderator.verifyTransfer(msg.sender, _to, _value, _data);
    }

    function canTransferFrom(address _from, address _to, uint256 _value, bytes memory _data) public view 
        returns (bool success, byte statusCode, bytes32 applicationCode) 
    {
        return moderator.verifyTransferFrom(_from, _to, msg.sender, _value, _data);
    }
}