// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/*

██████╗ ██████╗ ██████╗  █████╗ ███╗   ██╗██████╗  █████╗ ███████╗
██╔══██╗██╔══██╗██╔══██╗██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔════╝
██████╔╝██████╔╝██████╔╝███████║██╔██╗ ██║██║  ██║███████║███████╗
██╔═══╝ ██╔═══╝ ██╔═══╝ ██╔══██║██║╚██╗██║██║  ██║██╔══██║╚════██║
██║     ██║     ██║     ██║  ██║██║ ╚████║██████╔╝██║  ██║███████║
╚═╝     ╚═╝     ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚══════╝

*/

import "./PPPandas.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PPPandasV2 is Ownable, ERC721Enumerable, PaymentSplitter {

    using SafeMath for uint;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint public PANDA_PRICE = 0.02 ether;
    uint public MAX_PANDAS = 8888;
    uint public airdroppedPandas = 0;
    uint private reservedPandas = 88;
    uint public publicSaleStartTime = 1631631600;
    uint private pandasForSale = MAX_PANDAS - reservedPandas;
    uint public maxPerTx = 20;
    bool public hasLegndBeenClaim = false;
    PPPandas PandasV1;
    string private _baseURIextended;
    string public PROVENANCE;
    mapping(address => uint) NFTsToClaim;
    mapping(address => bool) isTeam;
    mapping(address => bool) hasClaimedTokens;
    bool private isSaleActive = false;

    address private coreTeam = 0xEDA7c5543585900b129887Ea1f3596B255275554;
    address payable PandasV1Addr = payable(0xc5410dc08e424B27E36e7Da098810386211Ac26e);

    address[] private _team = [coreTeam];
    uint256[] private _team_shares = [100];

    constructor()
        ERC721("PPPandas", "PPP")
        PaymentSplitter(_team, _team_shares)
    {
        _baseURIextended = "ipfs://bafybeig6osderxfz33b2xaqkx5kc363g77rkzkuqlbadcsuz55jemtjfdi/";
        isTeam[msg.sender] = true;
        isTeam[coreTeam] = true;

        NFTsToClaim[coreTeam] = reservedPandas;
        NFTsToClaim[0x290cB1eA2653Afcd1e3e5a89dDB49ccb2737Fd67] = 37;
        NFTsToClaim[0x9247502d319A57eF23A602ABcC4B1d0f180e3BC7] = 37;

        PandasV1 = PPPandas(PandasV1Addr);
    }

    // Modifiers

    modifier verifyGift(uint _amount) {
        require(_totalSupply() < pandasForSale, "Error 8,888: Sold Out!");
        require(_totalSupply().add(_amount) <= pandasForSale, "Hold up! Purchase would exceed max supply. Try a lower amount.");
        _;
    }

    modifier verifyClaim(address _addr, uint _amount) {
        require(NFTsToClaim[_addr] > 0, "Sorry! You dont have any shares to claim.");
        require(_amount <= NFTsToClaim[_addr], "Hold up! Purchase would exceed max supply. Try a lower amount.");
        _;
    }

    modifier verifyBuy(uint _amount) {
        require(isSaleActive != false, "Sorry, Sale must be active!");
        require(block.timestamp >= publicSaleStartTime, "Public Sale has not started yet!");
        require(_totalSupply() < pandasForSale, "Error 8,888 Sold Out!");
        require(_totalSupply().add(_amount) <= pandasForSale, "Hold up! Purchase would exceed max supply. Try a lower amount.");
        require(_amount <= maxPerTx, "Hey you can not buy more than 20 at one time. Try a smaller amount.");
        require(msg.value >= PANDA_PRICE.mul(_amount), "Dang! You dont have enough ETH!");
        _;
    }

    modifier onlyTeam() {
        require(isTeam[msg.sender] == true, "Sneaky sneaky! You are not part of the team");
        _;
    }

    // Setters

    function _baseURI() internal view override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function setReservedPandas(uint _newReserve) external onlyOwner {
        reservedPandas = _newReserve;
    }

    function increaseSupply() internal {
        _tokenIds.increment();
    }

    function _totalSupply() public view returns (uint) {
        return _tokenIds.current();
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        PROVENANCE = _provenanceHash;
    }

    function setPublicSaleDate(uint _newTime) external onlyOwner {
        publicSaleStartTime =_newTime;
    }

    function toggleSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function contractURI() public view returns (string memory) {
        return _baseURIextended;
    }

    function buyPPPandas(uint _amount) external payable verifyBuy(_amount) {
        address _to = msg.sender;
        for (uint i = 0; i < _amount; i++) {
            uint id = _totalSupply() + 1;
            if(id == 8833) {
                id = id + 1;
            }
            _safeMint(_to, id);
            increaseSupply();
        }
    }

    function giftManyPPPandas(address[] memory _addr) external onlyTeam verifyGift(_addr.length) {
        for (uint i = 0; i < _addr.length; i++) {
            address _to = _addr[i];
            uint id = _totalSupply() + 1;
            _safeMint(_to, id);
            increaseSupply();
        }
    }

    function claimPandas() external {
      uint oldBalance = PandasV1.balanceOf(msg.sender);
      require(oldBalance > 0, "Sorry you dont have any v1 Pandas");
      require(hasClaimedTokens[msg.sender] != true, "Sorry, your have already claimed your tokens");
      uint newBalance = (oldBalance * 2);
        for(uint i = 0; i < newBalance; i++){
            uint id = _totalSupply() + 1;
            console.log("Minted ID: ", id);
            _safeMint(msg.sender, id);
            increaseSupply();
            airdroppedPandas++;
        }
      hasClaimedTokens[msg.sender] = true;
    }

    function teamPandas(uint _amount) external onlyTeam verifyClaim(msg.sender, _amount) {
        address _addr = msg.sender;
        if(hasLegndBeenClaim == false && msg.sender == coreTeam){
            _safeMint(msg.sender, 8833);
            NFTsToClaim[_addr] = NFTsToClaim[_addr] - 1;
            increaseSupply();
            hasLegndBeenClaim = true;
        }
        else {
            for (uint i = 0; i < _amount; i++) {
                uint id = _totalSupply() + 1;
                _safeMint(msg.sender, id);
                NFTsToClaim[_addr] = NFTsToClaim[_addr] - 1;
                increaseSupply();
            }
        }
    }

    function setClaimAddress(address[] memory _addr) external onlyOwner {
        for (uint i = 0; i < _addr.length; i++) {
            NFTsToClaim[_addr[i]] = 37;
        }
    }

    function setPrice(uint _newPrice) external onlyOwner {
        PANDA_PRICE = _newPrice;
    }

    function setMaxSupply(uint _newSupply) external onlyOwner {
        MAX_PANDAS = _newSupply;
    }

    function getTotalAirdropped() public view returns (uint) {
        return airdroppedPandas;
    }

    // Withdraw

    function withdrawAll() external onlyTeam {
            release(payable(_team[0]));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function burnPanda(uint _tokenId) public onlyOwner{
        _burn(_tokenId);
    }
    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}

/**

 Generative Art: @Jim Dee
 Smart Contract Consultant: @realkelvinperez

 https://generativenfts.io/

**/