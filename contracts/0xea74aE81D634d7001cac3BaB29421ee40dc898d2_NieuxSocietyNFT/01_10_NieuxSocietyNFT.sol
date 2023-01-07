//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

// import "hardhat/console.sol";
import "erc721a/contracts/ERC721A.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NieuxSocietyNFT is
    ERC721A,
    IERC2981,
    Ownable,
    ReentrancyGuard
{
    uint256 public _cost = 0.001 ether;
    uint256 public maxSupply;
    
    bytes32 public merkleRoot = "";

    string private customBaseURI;
    
    bool public paused;

    struct Phase {
        uint256 maxMintLimit;
        string name;
    }

    uint8 public currentPhase;
    mapping(uint256 => Phase) public phases;

    mapping (address => mapping(uint256 => uint256)) public mintsForPhase;
    
    address public paymentSplitter;
    address public royaltyContract;
    address public useWinterAddress;
    address public useWinterCustodialAddress;
    
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        string memory customBaseURI_,
        bool paused_,
        uint256 _collectionSize,
        uint256 _maxMintLimit,
        string memory _phaseName,
        address paymentSplitter_,
        address royaltyContract_,
        address useWinterAddress_,
        address useWinterCustodialAddress_
    ) ERC721A(tokenName, tokenSymbol) ReentrancyGuard() {
        customBaseURI = customBaseURI_;
        paused = paused_;
        maxSupply = _collectionSize;

        Phase storage phase = phases[++currentPhase];
        phase.maxMintLimit = _maxMintLimit;
        phase.name = _phaseName;

        paymentSplitter = paymentSplitter_;
        royaltyContract = royaltyContract_;
        useWinterAddress = useWinterAddress_;
        useWinterCustodialAddress = useWinterCustodialAddress_;
    }

    function mint(uint256 amount)
        external
        payable
        nonReentrant
    {
        // require public phase
        require(keccak256(abi.encodePacked("Public")) == keccak256(abi.encodePacked(phases[currentPhase].name)), "not public");
        require(!paused, "paused");
        require((_totalMinted() + amount) <= maxSupply, "not enough supply");
        require(mintsForPhase[msg.sender][currentPhase] + amount <= phases[currentPhase].maxMintLimit, "Too many for phase");
        require(msg.value == (_cost * amount), "ether != cost");

        mintsForPhase[msg.sender][currentPhase] += amount;

        _mint(msg.sender, amount);

        (bool sent,) = payable(paymentSplitter).call{value: msg.value}("");
        require(sent, "Failed to pay Ether");

        emit Minted(msg.sender, amount);
    }

    function mintByMerkle(bytes32[] calldata _merkleProof, uint256 _amount)
        external
        payable
        nonReentrant
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "invalid merkle proof");

        require(!paused, "paused");
        require((_totalMinted() + _amount) <= maxSupply, "not enough supply");

        require(msg.value == (_cost * _amount), "ether != cost");
        require(mintsForPhase[msg.sender][currentPhase] + _amount <= phases[currentPhase].maxMintLimit, "Too many for phase");

        mintsForPhase[msg.sender][currentPhase] += _amount;

        _mint(msg.sender, _amount);

         (bool sent,) = payable(paymentSplitter).call{value: msg.value}("");
        require(sent, "Failed to pay Ether");

        emit Minted(msg.sender, _amount);
    }

    /*********
    * mint by winter functions
    */
    function mintByWinterMerkle(uint256 _amount, address _recipient, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
    {
        bytes32 leaf = keccak256(abi.encodePacked(_recipient));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "invalid merkle proof");

        require(!paused, "paused");
        require(msg.sender == useWinterAddress, "WINTER IS NOT HERE");
        require((_totalMinted() + _amount) <= maxSupply, "not enough supply");
        require(msg.value == (_cost * _amount), "ether != cost");
        if (_recipient != useWinterCustodialAddress) {
            require(mintsForPhase[_recipient][currentPhase] + _amount <= phases[currentPhase].maxMintLimit, "Too many for phase");
        }
        mintsForPhase[_recipient][currentPhase] += _amount;

        _mint(_recipient, _amount);

        (bool sent,) = payable(paymentSplitter).call{value: msg.value}("");
        require(sent, "Failed to pay Ether");

        emit Minted(_recipient, _amount);
    }

    function mintByWinter(uint256 _amount, address _recipient)
        external
        payable
        nonReentrant
    {
        require(!paused, "paused");
        require(msg.sender == useWinterAddress, "WINTER IS NOT HERE");
        require((_totalMinted() + _amount) <= maxSupply, "not enough supply");
        require(msg.value == (_cost * _amount), "ether != cost");
        if (_recipient != useWinterCustodialAddress) {
            require(mintsForPhase[_recipient][currentPhase] + _amount <= phases[currentPhase].maxMintLimit, "Too many for phase");
        }
        mintsForPhase[_recipient][currentPhase] += _amount;

        _mint(_recipient, _amount);

        (bool sent,) = payable(paymentSplitter).call{value: msg.value}("");
        require(sent, "Failed to pay Ether");

        emit Minted(_recipient, _amount);
    }

    /*********
     * mint by owner functions
     * to/amount
     */
    function mintByOwnerBulk(address[] memory to, uint256[] memory amount) 
        external 
        payable 
        onlyOwner
        nonReentrant
    {
        for (uint i = 0; i < to.length; i++) 
        {
            require((_totalMinted() + amount[i]) <= maxSupply, "not enough supply");

            _mint(to[i], amount[i]);

            emit Minted(to[i], amount[i]);
        }

        if (msg.value > 0)
        {
            (bool sent,) = payable(paymentSplitter).call{value: msg.value}("");
            require(sent, "Failed to pay Ether");
        }
    }

    function mintByOwner(uint256 _amount, address _recipient)
        external
        payable
        onlyOwner
    {
        require((_totalMinted() + _amount) <= maxSupply, "not enough supply");

        _mint(_recipient, _amount);

        if (msg.value > 0)
        {
            (bool sent,) = payable(paymentSplitter).call{value: msg.value}("");
            require(sent, "Failed to pay Ether");
        }

        emit Minted(_recipient, _amount);
    }

    /***************
     * update merkle proof
     */
    function updateMerkleRoot(bytes32 newRoot)
        external
        onlyOwner 
    {
        merkleRoot = newRoot;

        emit NewMerkleRoot(newRoot);
    }

    function isValidMerkleProof(bytes32[] calldata _merkleProof, address addr)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        
        bool isValidProof = MerkleProof.verify(
            _merkleProof,
            merkleRoot,
            leaf);

        return isValidProof;
    }
    
    /**************
        pause/unpause 
    */
    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    /*******************
        set phase
    */
    function setPhase(string memory _name, uint256 _maxMintForPhase)
        external
        onlyOwner
    {
        Phase storage phase = phases[++currentPhase];
        phase.maxMintLimit = _maxMintForPhase;
        phase.name = _name;
        emit PhaseChanged(_name, _maxMintForPhase);
    }

    /*****************
        pament splitter and royalty addresses
    */

    function setSplitterAddress(address paymentSplitter_)
        external 
        onlyOwner 
    {
        address old = paymentSplitter;
        paymentSplitter = paymentSplitter_;
        emit SplitterAddressChanged(old, paymentSplitter);
    }

    function setRoyaltyAddress(address royaltyContract_)
        external 
        onlyOwner 
    {
        address old = royaltyContract;
        royaltyContract = royaltyContract_;
        emit RoyaltyAddressChanged(old, royaltyContract);
    }

    function setUseWinterAddress(address useWinterAddress_)
        external 
        onlyOwner 
    {
        address old = useWinterAddress;
        useWinterAddress = useWinterAddress_;
        emit UseWinterAddressChanged(old, useWinterAddress);
    }

    function setUseWinterCustodialAddress(address useWinterCustodialAddress_)
        external 
        onlyOwner 
    {
        address old = useWinterCustodialAddress;
        useWinterCustodialAddress = useWinterCustodialAddress_;
        emit UseWinterCustodialAddressChanged(old, useWinterCustodialAddress);
    }

    /*****************
        token uri
    */
    function baseTokenURI()
        public
        view
        returns (string memory)
    {
        return customBaseURI;
    }

    function setBaseURI(string memory customBaseURI_) 
        external 
        onlyOwner 
    {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() 
        internal 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        return customBaseURI;
    }

    /**********
        supported interfaces 
    */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC721A, IERC165) returns (bool) 
    {   
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /***********
        IERC2981 interface
    */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        override
        view
        returns (address receiver, uint256 royaltyAmount) 
    {    
        royaltyAmount = (salePrice * 1000) / 10000;
        receiver = royaltyContract;

        return (receiver, royaltyAmount);
    }
    
    /*********
     * cost related functions
     */
    function setCost(uint256 newCost) 
        external
        onlyOwner
    {
        _cost = newCost;

        emit CostChanged(newCost);
    }

    function cost()
        public 
        view
        returns (uint256)
    {
        return _cost;
    }


    /**************
        public function to get state of mint
    */
    function mintState()
        public
        view
        returns (
            bool,
            Phase memory,
            uint256
        )
    {
        return (paused, phases[currentPhase], _cost);
    }

    /*************
        events
    */
    event Minted(address indexed to, uint256 amount);
    event MintByOwner(address indexed to, uint256 amount);
    event SplitterAddressChanged(address indexed from, address indexed to);
    event RoyaltyAddressChanged(address indexed from, address indexed to);
    event Paused();
    event Unpaused();
    event CostChanged(uint256 newCost);
    event PhaseChanged(string name, uint256 maxMintLimit);
    event NewMerkleRoot(bytes32 newMerkleRoot);
    event UseWinterAddressChanged(address indexed from, address indexed to);
    event UseWinterCustodialAddressChanged(address indexed from, address indexed to);

    /*******
     * errors
     */
    error UnknownPhase();


    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

     receive() external payable { 
        (bool sent,) = payable(paymentSplitter).call{value: msg.value}("");
        require(sent, "Failed to receive Ether");
    }
}