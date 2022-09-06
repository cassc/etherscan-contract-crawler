// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721NES.sol";

abstract contract Security {
    modifier onlySender() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}

interface IFSBContract {    
    function mintAirdrop(address _minter, uint256 _mintAmount) external;    
}

contract ElefrenETH is Ownable, ERC721NES, Security {
    uint256 public maxSupply = 5555;
    uint256 public maxSupplyBorneo = 2877;
    bool public mintIsActive;    
    uint256 public mintWlCost;
    uint256 public mintPublicCost;
    string private _baseTokenURI;
    mapping(address => uint256) private minter;
    mapping(address => bool) private freeMinter;
    mapping(address => uint256) private maximusMinter;
    bytes32 public merkleRoot;
    address signatureAddress = address(0x109491702DC66B91E5FAD7d586889679a86A8B76);
    mapping(uint256 => bool) private _nonces;

    uint256 multiplier = 1;

    // For each token, this map stores the current block.number
    // if token is mapped to 0, it is currently unstaked.
    mapping(uint256 => uint256) public tokenToWhenStaked;

    // For each token, this map stores the total duration staked
    // measured by block.number
    mapping(uint256 => uint256) public tokenToTotalDurationStaked;
    
    Phase public currentPhase;
    IFSBContract public fsbToken;

    enum Phase {         
        PhaseT,
        PhaseOO,
        PhaseTT,
        PhaseOOT
    }


    constructor() ERC721A("ELEFREN", "Elefren") {
        currentPhase = Phase.PhaseT;
    }
    
    function mintWl(bytes32[] calldata _merkleProof, uint256 _mintAmount, bool _toStake) external payable onlySender {
        uint256 _totalSupply = totalSupply();
        require(mintIsActive, "Mint is not live");        
        require(_totalSupply < maxSupplyBorneo, "Sold Out Borneo Phase");
        require(_totalSupply < maxSupply, "Sold Out");
        
        require(msg.value >= (_mintAmount * mintWlCost), "Not enought ETH");        

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Not allowed to mint"
        );

        minter[msg.sender] += _mintAmount;        
        _elefrenMint(_mintAmount, _toStake);
        fsbToken.mintAirdrop(msg.sender, _mintAmount);
    }

    function mintPublic(uint256 _mintAmount, bool _toStake) external payable onlySender {
        uint256 _totalSupply = totalSupply();
        require(mintIsActive, "Mint is not live");
        require(currentPhase == Phase.PhaseOO, "Public mint is not live");
        require(_totalSupply < maxSupplyBorneo, "Sold Out Borneo Phase");
        require(_totalSupply < maxSupply, "Sold Out");
        
        require(msg.value >= (_mintAmount * mintPublicCost), "Not enought ETH");
                        
        minter[msg.sender] += _mintAmount;   
        _elefrenMint(_mintAmount, _toStake); 
        fsbToken.mintAirdrop(msg.sender, _mintAmount);       
    }

    function mintFreeMaximus(bytes32[] calldata _merkleProof, bool _toStake) external onlySender {       
        uint256 _totalSupply = totalSupply(); 
        require(currentPhase >= Phase.PhaseTT, "Maximus phase TT is not live");        
        require(maxSupply > _totalSupply, "Sold Out");                
             
        require(!freeMinter[msg.sender], "You have already minted");
        

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Not allowed to mint"
        );

        freeMinter[msg.sender] = true;        
        _elefrenMint(1, _toStake);
    }

    function mintMaximus(uint256 _mintAmount, bytes32[] calldata _merkleProof, bool _toStake) external onlySender {       
        uint256 _totalSupply = totalSupply(); 
        require(currentPhase >= Phase.PhaseOOT, "Maximus phase OOT is not live");        
        require(maxSupply > _totalSupply, "Sold Out");        
               
        require(maximusMinter[msg.sender] + _mintAmount <= minter[msg.sender], "Exceed maximum allowed to mint");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Not allowed to mint"
        );

        maximusMinter[msg.sender] += _mintAmount;
        _elefrenMint(_mintAmount, _toStake);
    }
    

    function _elefrenMint(uint256 _quantity, bool _toStake) 
        private 
    {
        uint256 startIndex = _currentIndex;

        _mint(msg.sender, _quantity, "", false);
        
        if(_toStake) {
            for(uint256 i = startIndex; i < startIndex + _quantity; i++) {
                stake(i);
            }
        }
    }

     /**
     *  @dev returns the additional balance between when token was staked until now
     */
    function getCurrentAdditionalBalance(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        if (tokenToWhenStaked[tokenId] > 0) {
            return block.number - tokenToWhenStaked[tokenId];
        } else {
            return 0;
        }
    }

    /**
     *  @dev returns total duration the token has been staked.
     */
    function getCumulativeDurationStaked(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return
            tokenToTotalDurationStaked[tokenId] +
            getCurrentAdditionalBalance(tokenId);
    }

    /**
     *  @dev Returns the amount of tokens rewarded up until this point.
     */
    function getStakingRewards(uint256 tokenId) public view returns (uint256) {
        return getCumulativeDurationStaked(tokenId) * multiplier;
    }

    /**
     *  @dev Stakes a token and records the start block number or time stamp.
     */
    function stake(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of this token"
        );

        tokenToWhenStaked[tokenId] = block.number;
        _stake(tokenId);
    }

    /**
     *  @dev Unstakes a token and records the start block number or time stamp.
     */
    function unstake(uint256 tokenId, uint256 _nonce, bytes memory _signature) public 
        _validSignature(msg.sender, tokenId, _nonce, _signature) {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of this token"
        );

        require(!_nonces[_nonce], "Nonce already used");
        _nonces[_nonce] = true;

        tokenToTotalDurationStaked[tokenId] += getCurrentAdditionalBalance(
            tokenId
        );
        _unstake(tokenId);
    }


    modifier _validSignature(address _to, uint256 _tokenId, uint256 _nonce, bytes memory _signature){
        bytes32 message = keccak256(abi.encodePacked(_to, _tokenId, _nonce));
        assert(ECDSA.recover(message, _signature) == signatureAddress);
        _;
    }

    /* ADMIN ESSENTIALS */
    function adminMint(uint256 quantity, address _target) external onlyOwner {
        uint256 _totalSupply = totalSupply();
        require(maxSupply >= _totalSupply + quantity, "Sold out");                
        _mint(_target, quantity, "", false);
        
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMintWlCost(uint256 _mintWlCost) external onlyOwner {
        mintWlCost = _mintWlCost;
    }

    function setMintPublicCost(uint256 _mintPublicCost) external onlyOwner {
        mintPublicCost = _mintPublicCost;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function toggleSale() public onlyOwner {
        mintIsActive = !mintIsActive;
    }
 
    function setCurrentPhase(Phase phase) external onlyOwner {
        require(uint8(phase) <= 4, 'invalid phase');
        currentPhase = phase;        
    }

    function setFsbToken(address _fsbToken) external onlyOwner {
        fsbToken = IFSBContract(_fsbToken);
    }

    /* ADMIN ESSENTIALS */
    function hasMinted(address _addr) public view returns (uint256) {
        return minter[_addr];
    }

    function getCurrentPhase() public view returns (Phase) {
        return currentPhase;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}