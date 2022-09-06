// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FlipeetERC1155 is ERC1155, Ownable, ReentrancyGuard {

    uint256 public constant FLIPEET_COMMUNITY_NFT = 1;
    uint256 public constant FLIPEET_EXCLUSIVE_PASS = 2;
    string public name = "Flipeet Community";
    string public symbol;
    string public baseURI;
    uint256 public MintRate;
    string public contractURI;
    address public FeeReciever;
    uint256 public MintLimit = 5;
    uint256[] public Supplies = [20000,4000];
    uint256[] public Minted = [0,0];
    bool public saleIsActive = false;
    mapping(uint256 => bool) public TokensReadyForMint;
    mapping(uint256 => bytes32) public WhitelistMerkleRoots;
    mapping(address => mapping(uint256 => uint256)) public MintPerAddress;
    mapping(uint256 => mapping(address => bool)) public WhitelistClaimed;

    event MintLimitChanged(uint256 newMintlimit);
    event MintRateChanged(uint oldRate, uint newRate);
    event Transfer(address _to, uint _amount, uint _balance);
    event ContractURIChanged(string oldContractURI, string newContractURI);
    event ContractNameChanged(string oldContractName, string newContractName);
    event MintFeeRecieverChanged(address oldMintReciever, address newMintReciever);
    event ContractSymbolChanged(string oldContractSymbol, string newContractSymbol);


    constructor(string memory _uri, string memory _baseuri, uint _rate, address _feeReciever) ERC1155(_uri) {
        baseURI = _baseuri;
        MintRate = _rate;
        FeeReciever = _feeReciever;
    }

    /**
    *   Set token uri
    */
    function setURI(string memory _newuri, string memory _baseURI) external onlyOwner {
        _setURI(_newuri);
        baseURI = _baseURI;
    }

    /**
    *   Set contract collection uri
    */
    function setContractURI(string memory _contractURI) external onlyOwner {
        emit ContractURIChanged(contractURI, _contractURI);
        contractURI = _contractURI;
    }

    /**
    *   Set contract collection name
    */
    function setContractName(string memory _contractName) external onlyOwner {
        emit ContractNameChanged(name, _contractName);
        name = _contractName;
    }

    /**
    *   Set contract collection symbol
    */
    function setContractSymbol(string memory _contractSymbol) external onlyOwner {
        emit ContractSymbolChanged(symbol, _contractSymbol);
        symbol = _contractSymbol;
    }

    /**
    *   Set the minting rate (price)
    */
    function setMintRate(uint _rate) onlyOwner external {
        emit MintRateChanged(MintRate, _rate);
        MintRate = _rate;
    }

    /**
    *   Set the minting limit per address
    */
    function setMintLimit(uint256 _limit) onlyOwner external{
        emit MintLimitChanged(_limit);
        MintLimit = _limit;
    }

    /**
    *   Set the fee reciever
    */
    function setMintFeeReciever(address _newFeeReciever) external onlyOwner {
        emit MintFeeRecieverChanged(FeeReciever, _newFeeReciever);
        FeeReciever = _newFeeReciever;
    }

    /**
    *   Set merkle root for whitelisting for specified `_id`
    */
    function setMerkleRoot(uint _id, bytes32 _root) onlyOwner external {
        WhitelistMerkleRoots[_id] = _root;
    }

    /**
    *   Set if token of `_id` is ready for minting
    */
    function setTokenReadyForMint(uint _id) onlyOwner external {
        TokensReadyForMint[_id] = true;
    }

    /**
    *   Get merkle root whitelisted for specified `_id`
    */
    function getMerkleRoot(uint _id) onlyOwner external view returns(bytes32){
        return WhitelistMerkleRoots[_id];
    }

    /*
    *   Pause sale if active, make active if paused
    */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

 
    function uri(uint256 _id) override public view returns(string memory){
        return string(abi.encodePacked(baseURI, Strings.toString(_id), ".json"));
    }

    /**
     * @dev Mint `_id` of `_amount` to `sender`.
     *     
     * Requirements:
     *
     * - `_id` must exist.
     * - `_amount` not more than limit
     *
     */
    function mint(uint _id, uint _amount) external payable {
        require(saleIsActive, "FLIPEET: Sale not active");
        require(msg.sender != address(0), "FLIPEET: Mint to the zero address");
        require(TokensReadyForMint[_id], "FLIPEET: Token of id not ready for minting");
        require(_amount <= 5, "FLIPEET: Can only mint amount of 5 at a time");
        require(_id > 0 && _id <= Supplies.length, "FLIPEET: Token doesn't exist.");
        require(MintPerAddress[msg.sender][_id] < MintLimit, "FLIPEET: Address reached mint limit");
        require(MintPerAddress[msg.sender][_id] + _amount < MintLimit, "FLIPEET: Amount will exceed mint limit");
        require(msg.value >= (MintRate * _amount), "FLIPEET: Insufficient amount of ETH to mint.");
        require(Minted[_id - 1] + _amount <= Supplies[_id - 1], "FLIPEET: Not enough supply left.");

        _mint(msg.sender, _id, _amount, "");
        MintPerAddress[msg.sender][_id] += _amount;
        Minted[_id] += _amount;
    }

     /**
     * @dev Mint for WhiteListed Address  `_id` of `_amount` to `sender`.
     *     
     * Requirements:
     *
     * - `_id` must exist.
     * - `_amount` not more than limit
     * - `_proof` proof hash
     *
     */
    function mintWhitelist(uint _id, uint _amount, bytes32[] calldata _proof) external payable {
        require(saleIsActive, "FLIPEET: Sale not active");
        require(TokensReadyForMint[_id], "FLIPEET: Token of id not ready for minting");
        require(_amount <= 5, "FLIPEET: Can only mint amount of 5 at a time.");
        require(checkIfWhiteListed(_proof, _id), "FLIPEET: Invalid proof.");
        require(_id > 0 &&_id <= Supplies.length, "FLIPEET: Token doesn't exist.");
        require(msg.value >= (MintRate * _amount), "FLIPEET: Insufficient amount of ETH to mint.");
        require(Minted[_id - 1] + _amount <= Supplies[_id - 1], "FLIPEET: Not enough supply left.");
        require(MintPerAddress[msg.sender][_id] < MintLimit, "FLIPEET: Address reached mint limit.");
        require(MintPerAddress[msg.sender][_id] + _amount < MintLimit, "FLIPEET: Amount will exceed mint limit");
        require(!WhitelistClaimed[_id][msg.sender], "FLIPEET: Whitelist slot has already been claimed.");

        _mint(msg.sender, _id, _amount, "");
        WhitelistClaimed[_id][msg.sender] = true;
        MintPerAddress[msg.sender][_id] += _amount;
        Minted[_id] += _amount;
    }

    /**
    *   Verify if address is whitelisted
    */
    function checkIfWhiteListed(bytes32[] calldata _proof, uint _id) public view returns(bool isWhitelisted) {
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        bytes32 _root = WhitelistMerkleRoots[_id];

        isWhitelisted = MerkleProof.verify(_proof, _root, _leaf);
    }

    /**
    *   get amount minted for address by `_id`
    */
    function getMintedForWallet(uint256 _id) external view returns(uint256 mintedAmount){
        mintedAmount = MintPerAddress[msg.sender][_id];
    }

    /**
    *   get amount minted by `_id`
    */
    function getMintedAmount(uint256 _id) external view returns(uint256 mintedAmount){
        mintedAmount = Minted[_id];
    }

    /**
    *   returns - contract balance
    */
    function getBalance() external onlyOwner view returns(uint256){
      return address(this).balance;
    }


    function withdraw() external onlyOwner nonReentrant {
        transfer(payable(FeeReciever), address(this).balance);
    }

    function transfer(address payable _recipient, uint _amount) private 
    {
         (bool success, ) = _recipient.call{value : _amount}("");
         require(success, "FLIPEET: Transfer failed.");
         emit Transfer(_recipient, _amount, address(this).balance);
    }
}