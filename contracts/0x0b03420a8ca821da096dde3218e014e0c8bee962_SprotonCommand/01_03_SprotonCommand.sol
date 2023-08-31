pragma solidity ^0.8.17;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

interface INFT {
    function mintPFP(address to, uint tokenId) external;

    function mintGEN(address to, uint tokenId) external;

    function exist(uint tokenId) external view returns (bool);

    function ownerOf(uint tokenId) external view returns (address);

    function transferFrom(address from, address to, uint id) external;

    function balanceOf(address owner) external view returns (uint256);

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256);
}

contract SprotonCommand is Ownable {
    INFT _SPEPES;
    INFT _PFP;
    INFT _GEN;

    constructor(address SPEPES, address PFP, address GEN) {
        _SPEPES = INFT(SPEPES);
        _PFP = INFT(PFP);
        _GEN = INFT(GEN);
    }

    function batchMint(uint[] memory tokens) public {
        uint balance = _SPEPES.balanceOf(msg.sender);
        for(uint i=0; i<tokens.length; i++){
            uint tokenId = tokens[i];
            if (!_PFP.exist(tokenId)) { // skip if minted already
                require(!_PFP.exist(tokenId), "error PFP.exist");
                require(
                    msg.sender == _SPEPES.ownerOf(tokenId),
                    "error SPEPES.owner"
                );
                _PFP.mintPFP(msg.sender, tokenId);
                _GEN.mintGEN(msg.sender, tokenId);
            }
        }
    }

    function batchRecall(uint[] memory tokens) public {
        uint balance = _SPEPES.balanceOf(msg.sender);
        for(uint i=0; i<tokens.length; i++){
            uint tokenId = tokens[i];
            require(
                msg.sender == _SPEPES.ownerOf(tokenId), // ensure sender is owner
                "error SPEPES.owner"
            );
            if (_PFP.exist(tokenId)) { // skip if not minted yet
                require(_PFP.exist(tokenId), "error PFP.exist"); // has been minted
                if (msg.sender != _PFP.ownerOf(tokenId)) {
                    address pfpOwner = _PFP.ownerOf(tokenId);
                    _PFP.transferFrom(pfpOwner, msg.sender, tokenId);
                    _GEN.transferFrom(pfpOwner, msg.sender, tokenId);
                }
            }
        }
    }
}