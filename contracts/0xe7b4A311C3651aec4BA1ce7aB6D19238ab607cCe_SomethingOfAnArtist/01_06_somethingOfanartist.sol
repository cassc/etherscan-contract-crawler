// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./libA/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libA/ICanvas.sol";

contract SomethingOfAnArtist is ERC721A, Ownable {
    uint public constant MAX_SUPPLY = 5555;
    uint public constant MAX_FREE_PER_WALLET = 2;
    uint public constant MAX_FIRST_FREE = 2000;
    uint public constant MAX_PER_WALLET = 5;
    uint public price = 0.0069 ether;
    bool public sales;
    string public baseURI; //"ipfs:///"
    address canvas;
    ICanvas canvasContract;

    /// @notice phase
    uint public PHASE_START;
    uint public constant PHASE_DAY = 5; //5 days each human phase
    uint public forcedPhase = 5; // if > 4 = default phase

    //events
    event ForcePhase(uint phase);

    constructor(string memory _baseURI, uint timestamp) ERC721A("Something Of An Artist", "SOAA") {
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
        uint artistPhase = getPhase(timestamp);
        if (artistPhase == 0) return "Newborn";
        if (artistPhase == 1) return "Child";
        if (artistPhase == 2) return "Kid";
        if (artistPhase == 3) return "Teenager";
        if (artistPhase == 4) return "Adult";
    }

    function getCurrentPhase() external view returns (uint phase) {
        return getPhase(block.timestamp);
    }

    function getCurrentPhaseName() external view returns (string memory) {
        return getPhaseName(block.timestamp);
    }

    /******************** HUMAN EVENTS ********************/

    /// @notice 0-4: force a phase (0:new human, 4:full human), > 4: default phase
    function forceArtist(uint256 phase) external onlyOwner {
        forcedPhase = phase;
        emit ForcePhase(phase);
    }

    /******************** HUMAN EVENTS ********************/

    function setAddress(address _newAddress) external onlyOwner {
        canvasContract = ICanvas(_newAddress);
        canvas = _newAddress;
    }

    function configure() external onlyOwner {
        _mint(msg.sender, 1);
        canvasContract.mintCanvas(msg.sender, 1);
        setApprovalForAll(canvas, true);
    }

    function mint(uint _amt) external payable {
        require(sales, "pause!");
        require(tx.origin == msg.sender, "no bot!");
        require(MAX_SUPPLY >= _totalMinted() + _amt, "sold out!");
        require(_amt > 0 ,"must buy 1");
        require(_numberMinted(msg.sender) + _amt <= MAX_PER_WALLET,"Max per wallet exceeded!");

        if(_totalMinted() >= MAX_FIRST_FREE || _numberMinted(msg.sender) >= MAX_FREE_PER_WALLET){
            require(msg.value >= _amt * price, "Insufficient funds");
        }else{
            uint count = _numberMinted(msg.sender) + _amt;
            if(count > MAX_FREE_PER_WALLET){
                require(msg.value >= (count - MAX_FREE_PER_WALLET) * price , "Insufficient funds");
            } 
        }

        _mint(msg.sender, _amt);
        canvasContract.mintCanvas(msg.sender, _amt);
        setApprovalForAll(canvas, true);
    }

    /// @notice Team reserve.
    function teamMint(uint _amt, address to) external onlyOwner {
        require(MAX_SUPPLY >= _totalMinted() + _amt, "sold out!"); 
        uint batchMintAmount = _amt > 10 ? 10 : _amt;
        uint numChunks = _amt / batchMintAmount;
        for (uint i = 0; i < numChunks; ++i) {
            _mint(to, batchMintAmount);
            canvasContract.teamMintCanvas(to, batchMintAmount);
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "failed");
    }

    function setBaseURI(string calldata _url) external onlyOwner {
        baseURI = _url;
    }

    function getPrice() external view returns (uint){
        return price;
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

    function toggleSales(bool _sales) external onlyOwner {
        sales = _sales;
    }

    function transferArtist(address from, address to, uint tokenId) external {
        require(canvas == msg.sender, "Invalid source");
        safeTransferFrom(from, to, tokenId);
    }

    function _beforeTokenTransfers(address from,address to,uint tokenId, uint) internal override {
        if(from != address(0) && msg.sender != canvas){
            //ignore mint
            //transfer token(A+B) in one trx
            canvasContract.transferCanvas(from, to, tokenId);
        }
    }
}