// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PvSignedAllowlist.sol";
import './AbstractERC1155Factory.sol';

/*
* @title ERC1155 token for MintPass #2
*
* @author Niftydude
*/
contract MintPassTwo is PvSignedAllowlist, AbstractERC1155Factory {

    uint256 constant MAX_SUPPLY = 203282;

    uint256 public windowOpens;
    uint256 public windowCloses;

    address redeemContract;
    bool redeemContractFinalized;
    bool redeemEnabled;

    bool mintingClosed;

    constructor(
        string memory _name, 
        string memory _symbol,  
        string memory _uri,
        uint256 _windowOpens,
        uint256 _windowCloses
    ) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;

        windowOpens = _windowOpens;
        windowCloses = _windowCloses;

        _setSigner(msg.sender);
        _setTicketSupply(MAX_SUPPLY);

        _mint(msg.sender, 0, 10000, "");
    } 

    function mint(
        bytes calldata _signature, 
        uint256 _ticketId,
        uint256 _amount
    ) external {
        require(totalSupply(0) + _amount <= MAX_SUPPLY, "Max supply reached");
        require (block.timestamp > windowOpens && block.timestamp < windowCloses, "Window closed");
        require(!mintingClosed, "minting is closed");

        _verify(_signature, _ticketId, _amount);
        _invalidate(_ticketId);

        _mint(msg.sender, 0, _amount, "");
    } 

    function ownerMint (
        address[] calldata _to, 
        uint256[] calldata _amount
    ) external onlyOwner {
        require(_to.length == _amount.length, "same length required");
        require(!mintingClosed, "minting is closed");

        for(uint256 i; i < _to.length; i++) {
            require(totalSupply(0) + _amount[i] <= MAX_SUPPLY, "Max supply reached");
            _mint(_to[i], 0, _amount[i], "");
        }
    }        

    function burnFromRedeem(
        address _account, 
        uint256 _amount
    ) external {
        require(redeemContract == msg.sender, "Burnable: Only allowed from redeemable contract");
        require(redeemEnabled, "burn from redeem disabled");

        _burn(_account, 0, _amount);
    }  

    function editWindows(
        uint256 _windowOpens, 
        uint256 _windowCloses
    ) external onlyOwner {
        require(_windowOpens < _windowCloses, "open window must be before close window");

        windowOpens = _windowOpens;
        windowCloses = _windowCloses;
    }     

    function finalizeRedeemContract(
        address _redeemContract
    ) external onlyOwner {
        require(!redeemContractFinalized, "contract is finalized");

        redeemContract = _redeemContract;  
        redeemContractFinalized = true;
    } 

    function setURI(
        string memory _baseURI
    ) external onlyOwner {
        _setURI(_baseURI);
    }    

    function toggleRedeem() external onlyOwner {
        redeemEnabled = !redeemEnabled;
    }    

    function closeMintingForever() external onlyOwner {
        mintingClosed = true;
    }   

    function invalidateTickets(
        uint256[] calldata _ticketIds
    ) external onlyOwner {
        for(uint256 i; i < _ticketIds.length; i++) {
             _invalidate(_ticketIds[i]);
        }
    }

    function setSigner(
        address _signer
    ) external onlyOwner {
        _setSigner(_signer);
    }

    function resetWithNewSupply(
        uint256 _supply
    ) external onlyOwner {
        _setTicketSupply(_supply);
    }    
}