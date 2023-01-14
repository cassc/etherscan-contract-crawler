//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Upgrade is Initializable , ERC721Upgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, AccessControlUpgradeable {
    string internal notRevealedURI ;
    string internal rarityURI;
    string internal revealedURI;
    bytes32 private freeMintMerkleRoot;
    bytes32 private presaleMerkleRoot;

    uint256 public mintCost;
    uint256 public presaleCost;
    uint256 internal balanceMD;
    uint256 internal balanceBMD;
    uint256 internal paymentMintMD;
    uint256 internal paymentPresaleMD;
    uint32 public maxPerMint;
    string internal nftName;

    enum MintPeriod{ FREE, PRESALE, PUBLIC }
    uint32 public maxSupply;
    bool internal lockMD;
    bool internal lockBMD;

    mapping(address => bool) internal addressMintedMap;
    mapping(address => bool) internal addressMintedInFreeMintMap;
    mapping(address => bool) internal addressMintedInPresaleMap;
    mapping(uint256 => bool) internal revealTokenIdMap;

    // all time in GMT
    uint32 public freeMintStartTime;
    uint32 public freeMintEndTime;
    uint32 public presaleStartTime;
    uint32 public presaleEndTime;
    uint32 public publicSaleStartTime;
    uint32 public publicSaleEndTime;
    uint32 public showRarityTime;
    uint32 public revealTime;
    uint32 public allRevealTime;

    bytes32 public constant BENEFICIARY_ROLE = keccak256("BENEFICIARY");
    bytes32 public constant MD_ROLE = keccak256("MD");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");

    event MintEvent(address indexed buyerAddress, string ref,string status,string item,uint256 price,uint32 quantity, uint256 tokenId, string ipfs); 


    function initialize(address _admin, address _beneficiary, address _md, string memory _name, string memory _symbol) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        __AccessControl_init();
        __ERC721Enumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(BENEFICIARY_ROLE, _beneficiary);
        _setupRole(MD_ROLE, _md);
        _setRoleAdmin(OPERATOR_ROLE, DEFAULT_ADMIN_ROLE);
        nftName = _name;

        notRevealedURI = "ipfs://bafybeigye77uw5porgatddhr5fn4vhbucpgos7tgepniruqa4hwfjz4fje/";
        rarityURI = "ipfs://bafybeigzvcwlnsq7lkt64jg7pf7lp55v3bp5ezkl7unlvxdlqfvcw6f5ou/";
        revealedURI = "ipfs://bafybeifvjm42eeudihmvxobh5qsib3l5lval6u5hhk6bwsvhm5wh6bm73a/";
        freeMintMerkleRoot = 
            0xc929a9041c1b56b58ba3c8c7bf2502d66c54e8206085a1892fe3c58518b3387c;
        presaleMerkleRoot =
            0x9ed9f01a6617358dcc2c8e558f1289a2a325dcac07a0054a6e6b713e67e75aba;

        mintCost = 0.1 ether;
        presaleCost = 0.08 ether;
        paymentMintMD = mintCost * 19/20;
        paymentPresaleMD = presaleCost * 19/20;
        maxPerMint = 1;
    
        maxSupply = 3888;
        lockMD = false;
        lockBMD = false;
    
    
        // all time in GMT
        freeMintStartTime = 1658581200;
        freeMintEndTime = 1658667600;
        presaleStartTime = 1658581200;
        presaleEndTime = 1658667600;
        publicSaleStartTime = 1659013200;
        publicSaleEndTime = 1659186000;
        showRarityTime = 1659445200;
        revealTime = 1659618000;
        allRevealTime = 1659704400;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721EnumerableUpgradeable, ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721EnumerableUpgradeable, ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function isFreeMintPeriod() public view returns (bool) {
        uint256 currentTime = block.timestamp;
        if (currentTime > freeMintStartTime && currentTime < freeMintEndTime) {
            return true;
        }

        return false;
    }

    function isPresalePeriod() public view returns (bool) {
        uint256 currentTime = block.timestamp;
        if (currentTime > presaleStartTime && currentTime < presaleEndTime) {
            return true;
        }

        return false;
    }

    function isPublicSalePeriod() public view returns (bool) {
        uint256 currentTime = block.timestamp;
        if (
            currentTime > publicSaleStartTime && currentTime < publicSaleEndTime
        ) {
            return true;
        }

        return false;
    }

    function isRevealed(uint256 tokenId) public view returns (bool){
        if(revealTokenIdMap[tokenId] == true){
            return true;
        }
        return false;
    }

    // ------ Operator Only ------

    function setFreeMintMerkleRoot(bytes32 _root)
        public
        onlyRole(OPERATOR_ROLE)
    {
        freeMintMerkleRoot = _root;
    }

    function setPresaleMerkleRoot(bytes32 _root)
        public
        onlyRole(OPERATOR_ROLE)
    {
        presaleMerkleRoot = _root;
    }

    function setMintCost(uint256 _cost) public onlyRole(OPERATOR_ROLE) {
        mintCost = _cost;
    }

    function setPresaleCost(uint256 _cost) public onlyRole(OPERATOR_ROLE) {
        presaleCost = _cost;
    }

    function setMaxPerMint(uint32 _max) public onlyRole(OPERATOR_ROLE) {
        maxPerMint = _max;
    }

    function setFreeMintStartTime(uint32 _time) public onlyRole(OPERATOR_ROLE) {
        freeMintStartTime = _time;
    }

    function setFreeMintEndTime(uint32 _time) public onlyRole(OPERATOR_ROLE) {
        freeMintEndTime = _time;
    }

    function setPresaleStartTime(uint32 _time) public onlyRole(OPERATOR_ROLE) {
        presaleStartTime = _time;
    }

    function setPresaleEndTime(uint32 _time) public onlyRole(OPERATOR_ROLE) {
        presaleEndTime = _time;
    }

    function setPublicSaleStartTime(uint32 _time)
        public
        onlyRole(OPERATOR_ROLE)
    {
        publicSaleStartTime = _time;
    }

    function setPublicSaleEndTime(uint32 _time) public onlyRole(OPERATOR_ROLE) {
        publicSaleEndTime = _time;
    }

    function setShowRarityTime(uint32 _time) public onlyRole(OPERATOR_ROLE) {
        showRarityTime = _time;
    }

    function setRevealTime(uint32 _time) public onlyRole(OPERATOR_ROLE) {
        revealTime = _time;
    }

    function setAllRevealTime(uint32 _time) public onlyRole(OPERATOR_ROLE) {
        allRevealTime = _time;
    }

    function setNotRevealedURI(string memory _notRevealedURI)
        public
        onlyRole(OPERATOR_ROLE)
    {
        notRevealedURI = _notRevealedURI;
    }

    function setRarityURI(string memory _rarityURI)
        public
        onlyRole(OPERATOR_ROLE)
    {
        rarityURI = _rarityURI;
    }

    function setRevealedURI(string memory _revealedURI)
        public
        onlyRole(OPERATOR_ROLE)
    {
        revealedURI = _revealedURI;
    }

    function revealNFT(uint256 _tokenId) public{
        revealTokenIdMap[_tokenId] = true;
    }

    // ------ Beneficiary Only ------

    function withdrawMD() public payable onlyRole(MD_ROLE) {
        require(!lockMD);
        lockMD = true;
        uint256 tempBalance = balanceMD;
        require(tempBalance > 0, "No eth balance");
        (bool success, ) = payable(_msgSender()).call{
            value: tempBalance
        }("");
        require(success);
        balanceMD -= tempBalance;
        lockMD = false;
    }

     function withdrawBMD() public payable onlyRole(BENEFICIARY_ROLE) {
        require(!lockBMD);
        lockBMD = true;
        uint256 tempBalance = balanceBMD;
        require(tempBalance > 0, "No eth balance");
        (bool success, ) = payable(_msgSender()).call{
            value: tempBalance
        }("");
        require(success);
        balanceBMD -= tempBalance;
        lockBMD = false;
    }

    

    // ------ Mint ------

    function freeMint(uint32 count, bytes32[] calldata proof)
        external
        payable
        preMintChecks(count, MintPeriod.FREE)
    {
        if (isFreeMintPeriod()) {
            require(freeMintMerkleRoot != "", "Free mint not ready");
            require(
                MerkleProof.verify(
                    proof,
                    freeMintMerkleRoot,
                    keccak256(abi.encodePacked(_msgSender()))
                ),
                "Not a free mint member"
            );
            require(
                addressMintedInFreeMintMap[_msgSender()] == false,
                "Already minted"
            );
        } else {
            revert("Free mint not opened");
        }

        performMint(count);

        addressMintedInFreeMintMap[_msgSender()] = true;
    }

    function presaleMint(uint32 count, bytes32[] calldata proof)
        external
        payable
        preMintChecks(count, MintPeriod.PRESALE)
    {
        if (isPresalePeriod()) {
            require(presaleMerkleRoot != "", "Presale not ready");
            require(
                MerkleProof.verify(
                    proof,
                    presaleMerkleRoot,
                    keccak256(abi.encodePacked(_msgSender()))
                ),
                "Not a presale member"
            );
            require(
                addressMintedInPresaleMap[_msgSender()] == false,
                "Already minted"
            );
        } else {
            revert("Presale not opened");
        }

        performMint(count);
        balanceMD += paymentPresaleMD * count;
        balanceBMD += (presaleCost-paymentPresaleMD) * count;

        addressMintedInPresaleMap[_msgSender()] = true;
    }

    function mint(uint32 count, string memory referralCode) public payable preMintChecks(count, MintPeriod.PUBLIC) {
        //        require(open == true, "Mint not open");
        if (isPublicSalePeriod()) {
            require(addressMintedMap[_msgSender()] == false, "Already minted");
        } else {
            revert("Not opened");
        }

        performMint(count);

        balanceMD += paymentMintMD * count;
        balanceBMD += (mintCost-paymentMintMD) * count;
        
        addressMintedMap[_msgSender()] = true;
        emit MintEvent(_msgSender(), referralCode ,"P", nftName , mintCost*count, count , totalSupply(), tokenURI(totalSupply()));
    }

    function mint(uint32 count) public payable preMintChecks(count, MintPeriod.PUBLIC) {
        mint(count, "");
    }

    function performMint(uint32 count) internal {
        uint256 supply = totalSupply();

        for (uint32 i = 0; i < count; i++) {
            _safeMint(_msgSender(), ++supply, "");
        }
    }

    // ------ Read ------
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        uint256 currentTime = block.timestamp;
        string memory targetURI;
        if (currentTime < showRarityTime) {
            targetURI = string(abi.encodePacked(notRevealedURI,Strings.toString(tokenId),".json"));
        } else if (currentTime < revealTime) {
            targetURI = string(abi.encodePacked(rarityURI,Strings.toString(tokenId),".json"));
        } else if(currentTime < allRevealTime){
            if(isRevealed(tokenId)){
                targetURI = string(abi.encodePacked(revealedURI,Strings.toString(tokenId),".json"));
            } else {
                targetURI = string(abi.encodePacked(rarityURI,Strings.toString(tokenId),".json"));
            }
        } else {
            targetURI = string(abi.encodePacked(revealedURI,Strings.toString(tokenId),".json"));
        }

        return
            bytes(targetURI).length > 0
                ? targetURI
                : "";
    }

    // ------ Modifiers ------

    modifier preMintChecks(uint32 count, MintPeriod period) {
        uint256 supply = totalSupply();

        require(count > 0, "Mint at least one.");
        require(count < maxPerMint + 1, "Max mint reached.");
        if(period != MintPeriod.FREE){
            if(period == MintPeriod.PUBLIC){
                require(msg.value >= mintCost * count, "Not enough fund.");
            } else {
                require(msg.value >= presaleCost * count, "Not enough fund.");
            }         
        }     
        require(supply + count < maxSupply + 1, "Mint sold out");
        _;
    }
}