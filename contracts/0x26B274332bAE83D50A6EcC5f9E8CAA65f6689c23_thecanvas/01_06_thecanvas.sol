// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./libB/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libB/IArtist.sol";

contract thecanvas is ERC721A, Ownable {
    uint public constant MAX_SUPPLY = 5555;
    string public baseURI;
    address artist;
    IArtist artistContract;

    /// @notice phase
    uint public PHASE_START;
    uint public constant PHASE_DAY = 5; //5 days each human phase
    uint public forcedPhase = 5; // if > 4 = default phase

    //events
    event ForcePhase(uint phase);
    
    constructor(string memory _baseURI, uint timestamp) ERC721A("The Canvas", "TCVS") {
        baseURI = _baseURI;
        PHASE_START = timestamp;
    }

    /******************** TRANSFORMATION PHASE ********************/
    function getPhase(uint timestamp) public view returns (uint phase) {
        //check if there's any forced phase
        if (forcedPhase >= 0 && forcedPhase <= 4) {
            return forcedPhase;
        }

        uint daysFromStart = ((timestamp - PHASE_START) / 60 / 60 / 24) / PHASE_DAY;
        if (daysFromStart >= 4) return 4;
        return daysFromStart;
    }

    function getPhaseName(uint timestamp) public view returns (string memory phase) {
        uint canvasPhase = getPhase(timestamp);
        if (canvasPhase == 0) return "Newborn's Canvas";
        if (canvasPhase == 1) return "Child's Canvas";
        if (canvasPhase == 2) return "Kid's Canvas";
        if (canvasPhase == 3) return "Teenager's Canvas";
        if (canvasPhase == 4) return "Adult's Canvas";
    }

    function getCurrentPhase() external view returns (uint phase) {
        return getPhase(block.timestamp);
    }

    function getCurrentPhaseName() external view returns (string memory) {
        return getPhaseName(block.timestamp);
    }

    /******************** HUMAN EVENTS ********************/

    /// @notice 0-4: force a phase (0:new human, 4:full human), > 4: default phase
    function forceCanvas(uint256 phase) external onlyOwner {
        forcedPhase = phase;
        emit ForcePhase(phase);
    }

    /******************** HUMAN EVENTS ********************/

    function setAddress(address _newAddress) external onlyOwner {
        artistContract = IArtist(_newAddress);
        artist = _newAddress;
    }

    function mintCanvas(address to, uint amt) external {
        require(MAX_SUPPLY >= _totalMinted() + amt, "sold out!");
        require(artist == msg.sender, "Invalid source");
        _mint(to, amt);
        setApprovalForAll(artist, true);
    }

    function teamMintCanvas(address to, uint amt) external {
        require(MAX_SUPPLY >= _totalMinted() + amt, "sold out!");
        require(artist == msg.sender, "Invalid source");
        _mint(to, amt);
    }
   
    function transferCanvas(address from, address to, uint tokenId) external {
        require(artist == msg.sender, "Invalid source");
        safeTransferFrom(from, to, tokenId);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "failed");
    }

    function setBaseURI(string calldata _url) external onlyOwner {
        baseURI = _url;
    }

    function tokenURI(uint _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Invalid tokenId");
        uint currentPhase = getPhase(block.timestamp);

        if (currentPhase > 0) {
            return string(abi.encodePacked(baseURI, _toString(_tokenId), "_", _toString(currentPhase), ".json"));
        } 

        return string(abi.encodePacked(baseURI,_toString(_tokenId),".json"));
    }

    function _startTokenId() internal view virtual override returns (uint) {
        return 1;
    }

    function _beforeTokenTransfers(address from,address to,uint tokenId, uint) internal override {
        if(from != address(0) && msg.sender != artist){
            //ignore mint
            artistContract.transferArtist(from, to, tokenId);
        }
    }

    function setApprovalForAll(address operator, bool approved) public override {
        address sender;
        if(operator != artist){
            if (operator == _msgSenderERC721A()) revert ApproveToCaller();
            sender = _msgSenderERC721A();
        }else{
            sender = tx.origin;
        }
        
        _operatorApprovals[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }
}