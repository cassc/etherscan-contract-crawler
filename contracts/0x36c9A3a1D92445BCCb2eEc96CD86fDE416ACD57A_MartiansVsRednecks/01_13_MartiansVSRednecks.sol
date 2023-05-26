// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MartiansVsRednecks is Ownable, ERC721A {
    
    string private _baseTokenURI;
    
    uint public constant MAX_MVSR = 6667;
    uint public MAX_SALE = 10;
    uint public MAX_PRESALE = 5;
    
    address private teamAddress1;
    address private teamAddress2;
    address private teamAddress3;
    address private teamAddress4;
    address private netvrkAddress;
    address private devTeamAddress;

    uint public price;
    
    bytes32 public merkleRoot;
    
    bool public hasPreSaleStarted = false;
    bool public preSaleOver = false;
    bool public hasSaleStarted = false;

    modifier onlyDev() {
        require(devTeamAddress == _msgSender(), "MartiansVsRednecks::onlyDev: caller is not the dev.");
        _;
    }
    
    constructor(
        string memory baseURI_,
        bytes32 _merkleRoot
        ) ERC721A(
            "MartiansVsRednecks", 
            "MVRV1",
            300,
            MAX_MVSR
        ) {

        price = 0.1 ether;

        netvrkAddress = 0x901FC05c4a4bC027a8979089D716b6793052Cc16;
        devTeamAddress = 0x71298E004c85e339C90390Df54e9265c4fF7b285;
        teamAddress1 = 0xaA9CB1fa773c3d36E79Ad39Ba116D8FF28344203;
        teamAddress2 = 0x9eA791D214aFE8FCb0257DC3e8fcf54C3AD35171;
        teamAddress3 = 0x3Bc057a2b4bb703FC5c02D2eAeDB63eD517F31DD;
        teamAddress4 = 0x49F2f8802531421873669Af560D99579fe243a21;

        _baseTokenURI = baseURI_;

        merkleRoot = _merkleRoot;
    }

    function mint(uint _quantity) external payable  {
        require(hasSaleStarted, "MartiansVsRednecks::mint: Sale hasn't started.");
        require(_quantity > 0, "MartiansVsRednecks::mint: Quantity cannot be zero.");
        require(_quantity <= MAX_SALE, "MartiansVsRednecks::mint: Quantity cannot be bigger than MAX_BUYING.");
        require(totalSupply() + _quantity <= MAX_MVSR, "MartiansVsRednecks::mint: Sold out.");
        require(msg.value >= price * _quantity, "MartiansVsRednecks::mint: Ether value sent is below the price.");
        
        _safeMint(msg.sender, _quantity);
    }

    function preMint(
        uint _quantity,
        bytes32[] calldata merkleProof
    ) external payable  {
        require(hasPreSaleStarted, "MartiansVsRednecks::preMint: Presale hasn't started.");
        require(!preSaleOver, "MartiansVsRednecks::preMint: Presale is over, no more allowances.");
        require(_quantity > 0, "MartiansVsRednecks::preMint: Quantity cannot be zero.");
        require(_quantity <= MAX_PRESALE, "MartiansVsRednecks::preMint: Quantity cannot be bigger than MAX_PRESALE.");
        require(_numberMinted(msg.sender) + _quantity <= MAX_PRESALE, "MartiansVsRednecks::preMint: The user is not allowed to do further presale buyings.");
        require(totalSupply() + _quantity <= MAX_MVSR, "MartiansVsRednecks::preMint: Sold out");
        require(msg.value >= price *_quantity, "MartiansVsRednecks::preMint: Ether value sent is below the price.");
        
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MartiansVsRednecks::preMint: Invalid merkle proof."
        );
        
        _safeMint(msg.sender, _quantity);
    }
    
    function mintByOwner(address _to, uint256 _quantity) public onlyOwner {
        require(_quantity > 0, "MartiansVsRednecks::mintByOwner: Quantity cannot be zero.");
        require(totalSupply() + _quantity <= MAX_MVSR, "MartiansVsRednecks::mintByOwner: Sold out.");
        
        _safeMint(_to, _quantity);
    }
    
    function batchMintByOwner(address[] memory _mintAddressList, uint256[] memory _quantityList) external onlyOwner {
        require (_mintAddressList.length == _quantityList.length, "MartiansVsRednecks::batchMintByOwner: The length should be same");

        for (uint256 i = 0; i < _mintAddressList.length; i += 1) {
            mintByOwner(_mintAddressList[i], _quantityList[i]);
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setSaleMax(uint _saleMax) external onlyOwner {
        MAX_SALE = _saleMax;
    }

    function setPreSaleMax(uint _preSaleMax) external onlyOwner {
        MAX_PRESALE = _preSaleMax;
    }
    
    function startSale() external onlyOwner {
        require(!hasSaleStarted, "MartiansVsRednecks::startSale: Sale already active.");
        
        hasSaleStarted = true;
        hasPreSaleStarted = false;
        preSaleOver = true;
    }

    function pauseSale() external onlyOwner {
        require(hasSaleStarted, "MartiansVsRednecks::pauseSale: Sale is not active.");
        
        hasSaleStarted = false;
    }
    
    function startPreSale() external onlyOwner {
        require(!preSaleOver, "MartiansVsRednecks::startPreSale: Presale is over, cannot start again.");
        require(!hasPreSaleStarted, "MartiansVsRednecks::startPreSale: Presale already active.");
        
        hasPreSaleStarted = true;
    }

    function pausePreSale() external onlyOwner {
        require(hasPreSaleStarted, "MartiansVsRednecks::pausePreSale: Presale is not active.");
        
        hasPreSaleStarted = false;
    }

    function setTeamAddress1(address _teamAddress1) external onlyOwner {
        teamAddress1 = _teamAddress1;
    }

    function setTeamAddress2(address _teamAddress2) external onlyOwner {
        teamAddress2 = _teamAddress2;
    }

    function setTeamAddress3(address _teamAddress3) external onlyOwner {
        teamAddress3 = _teamAddress3;
    }

    function setTeamAddress4(address _teamAddress4) external onlyOwner {
        teamAddress3 = _teamAddress4;
    }

    function setNetvrkAddress(address _netvrksAddress) external onlyOwner {
        netvrkAddress = _netvrksAddress;
    }

    function setDevTeamAddress(address _devTeamAddress) external onlyDev {
        devTeamAddress = _devTeamAddress;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }
    
    function withdrawETH() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 devTeamAmount = totalBalance;

        uint256 teamAmount = (totalBalance * 1750) / 10000;  // 17.5 for every team member
        uint256 netvrkAmount = (totalBalance * 2000) / 10000; // 20% for Netvrk
        devTeamAmount = devTeamAmount - (teamAmount * 4) - netvrkAmount; // resting 10% for dev team

        (bool withdrawTeam1, ) = teamAddress1.call{value: teamAmount}("");
        require(withdrawTeam1, "Withdraw Failed To Team address 1.");

        (bool withdrawTeam2, ) = teamAddress2.call{value: teamAmount}("");
        require(withdrawTeam2, "Withdraw Failed To Team address 2.");

        (bool withdrawTeam3, ) = teamAddress3.call{value: teamAmount}("");
        require(withdrawTeam3, "Withdraw Failed To Team address 3.");

        (bool withdrawTeam4, ) = teamAddress4.call{value: teamAmount}("");
        require(withdrawTeam4, "Withdraw Failed To Team address 4.");

        (bool withdrawNetvrk, ) = netvrkAddress.call{value: netvrkAmount}("");
        require(withdrawNetvrk, "Withdraw Failed To Netvrk.");

        (bool withdrawDevTeam, ) = devTeamAddress.call{value: devTeamAmount}("");
        require(withdrawDevTeam, "Withdraw Failed To Dev Team.");
    }
}