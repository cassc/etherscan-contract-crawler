// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IScrapV2 {
    function increaseScrapBalance(address _address, uint256 _amount) external;
}

contract ElderApez is ERC721("Elder Apez", "ELDER"), ERC721Enumerable, Ownable {
    bool public isWLReservePhase = false;
    bool public isPublicReservePhase = false;
    bool public isBurnPhase = false;
    bool public isClaimPhase = false;
    bool public stakeLocked = true;
    uint256 internal maxSupply = 0;
    uint256 public mintPrice = 0.15 ether;
    uint256 public reservedSupply = 0;
    mapping(uint256 => address) public reserveAddress;
    mapping(address => uint256[]) public staked;
    mapping(address => uint256) public numReserved;
    mapping(address => uint256) public scrapClaimEpoch;
    bytes32 public merkleRoot;
    string public baseURI;
    ERC20 public ScrapV1 = ERC20(0xEEdcd8448bC38A6f43A3aa18651F44782c318fD0);
    IScrapV2 public ScrapV2 = IScrapV2(0x829cE04A6114e11217B6DcF38884d15260e569d0);
    ERC721 public DystoApez = ERC721(0x648E8428e0104Ec7D08667866a3568a72Fe3898F);

    event ScoreIncrease(uint256 indexed tokenId, uint256 indexed amount);
    
    function setMaxSupply(uint256 value) external onlyOwner {
        require(value > 0 && totalSupply() < value && reservedSupply < value, "Invalid max supply");
        maxSupply = value;
    }

    function setMintPrice(uint256 value) external onlyOwner {
        require(value >= 0, "Invalid mint price");
        mintPrice = value;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setScrapV1(address _scrapV1) external onlyOwner {
        ScrapV1 = ERC20(_scrapV1);
    }

    function setScrapV2(address _scrapV2) external onlyOwner {
        ScrapV2 = IScrapV2(_scrapV2);
    }

    function setDystoApez(address _dystoApez) external onlyOwner {
        DystoApez = ERC721(_dystoApez);
    } 

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function startWLReservePhase() external onlyOwner {
        require(!isWLReservePhase, "Whitelist reserve already started");
        require(!isPublicReservePhase && !isBurnPhase && !isClaimPhase, "Whitelist reserve phase cannot be started while other phases are active");
        isWLReservePhase = true;
    }

    function startPublicReservePhase() external onlyOwner {
        require(isWLReservePhase, "Public reserve phase can only start after the whitelist reserve phase");
        isPublicReservePhase = true;
        isWLReservePhase = false;
    }

    function startBurnPhase() external onlyOwner {
        require(isPublicReservePhase, "Burn can only start phase after the public reserve phase");
        isBurnPhase = true;
        isPublicReservePhase = false;
    }

    function startClaimPhase() external onlyOwner {
        require(isBurnPhase, "Claim phase can only start after the burn phase");
        isClaimPhase = true;
        isBurnPhase = false;
    }

    function stopAllPhases() external onlyOwner {
        isWLReservePhase = false;
        isPublicReservePhase = false;
        isBurnPhase = false;
        isClaimPhase = false;
    }

    function lockStaking() external onlyOwner {
        require(!stakeLocked, "Staking is already locked");
        stakeLocked = true;
    }

    function unlockStaking() external onlyOwner {
        require(stakeLocked, "Staking is already unlocked");
        stakeLocked = false;
    }

    function withdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawERC20(address tokenAddress) external onlyOwner {
        ERC20 ERC20Contract = ERC20(tokenAddress);
        ERC20Contract.transfer(msg.sender, ERC20Contract.balanceOf(address(this)));
    }

    function adminMint(uint256 amount) external onlyOwner {
        require (reservedSupply + amount <= maxSupply, "Max supply exceeded");
        for (uint256 i = 1; i <= amount; i = unsafe_inc(i)){
            reserveAddress[reservedSupply + i] = msg.sender;
            _safeMint(msg.sender, reservedSupply + i);
        }
        numReserved[msg.sender] += amount;
        reservedSupply += amount;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function unsafe_inc(uint256 x) internal pure returns (uint256) {
        unchecked { 
            return x + 1; 
        }
    }
    
    function isWhitelisted(bytes32[] calldata _merkleProof, address user) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function reservedTokenOfOwnerByIndex(address user, uint256 index) public view returns (uint256) {
        require(index < numReserved[user], "Index out of bounds");
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= reservedSupply; i++){
            if (reserveAddress[i] == user) {
                if (currentIndex == index) {
                    return i;
                }
                currentIndex += 1;
            }
        }
        return 0;
    }

    function reserveElderWL(uint256[] calldata tokenIds, bytes32[] calldata _merkleProof) public payable {
        require(isWLReservePhase, "Whitelist reserve phase is not active");
        require(tokenIds.length == 5 || tokenIds.length == 10, "Cannot stake this amount of Dysto Apez");
        uint256 reserveAmount = tokenIds.length/5;
        require(msg.value >= mintPrice*reserveAmount, "Not enough ETH to complete this transaction");
        require((reservedSupply + reserveAmount) <= maxSupply, "Max reserve supply exceeded");
        require((numReserved[msg.sender] + reserveAmount) <= 2, "Max mint for this address has been exceeded");
        require(isWhitelisted(_merkleProof, msg.sender), "Address not whitelisted");
        for (uint256 i = 1; i <= reserveAmount; i = unsafe_inc(i)) {
            reserveAddress[reservedSupply + i] = msg.sender;
        }
        scrapClaimEpoch[msg.sender] = block.timestamp;
        reservedSupply += reserveAmount;
        numReserved[msg.sender] += reserveAmount;
        for (uint256 i = 0; i < tokenIds.length; i = unsafe_inc(i)) {
            staked[msg.sender].push(tokenIds[i]);
            DystoApez.transferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }

    function reserveElderPublic(uint256[5] calldata tokenIds) public payable {
        require(isPublicReservePhase, "Public reserve phase is not active");
        require(msg.value >= mintPrice, "Not enough ETH to complete this transaction");
        require(reservedSupply < maxSupply, "Max reserve supply exceeded");
        require(numReserved[msg.sender] == 0, "Max mint for this address has been exceeded");
        reservedSupply += 1;
        numReserved[msg.sender] += 1;
        reserveAddress[reservedSupply] = msg.sender;
        staked[msg.sender] = tokenIds;
        scrapClaimEpoch[msg.sender] = block.timestamp;
        for (uint256 i = 0; i < 5; i = unsafe_inc(i)) {
            DystoApez.transferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }

    function increaseScore(uint256 tokenId, uint256 amount, bytes32[] calldata _merkleProof) public {
        require(isBurnPhase, "Burn phase is not active");
        require(reserveAddress[tokenId] == msg.sender, "Address did not reserve this Elder Ape");
        uint256 multiplier;
        if (isWhitelisted(_merkleProof, msg.sender)) {
            multiplier = 4;
        } else {
            multiplier = 1;
        }
        ScrapV1.transferFrom(msg.sender, address(this), amount);
        emit ScoreIncrease(tokenId, amount*multiplier); 
    }

    function claimElderApe(uint256 tokenId) public {
        require(isClaimPhase, "Claim phase is not active");
        require(reserveAddress[tokenId] == msg.sender, "Address did not reserve this Elder Ape");
        require(totalSupply() < maxSupply, "Max mint supply exceeded");
        _safeMint(msg.sender, tokenId);
    }

    function unstakeDystoApez() public {
        require(!stakeLocked, "Unstaking is not possible yet");
        require(staked[msg.sender].length > 0, "This address has no staked Dysto Apez");
        for (uint256 i = 0; i < staked[msg.sender].length; i = unsafe_inc(i)) {
            DystoApez.transferFrom(address(this), msg.sender, staked[msg.sender][i]);
        }
        claimScrap();
        delete staked[msg.sender];
    }

    function claimScrap() public {
        require (block.timestamp > scrapClaimEpoch[msg.sender], "Cannot claim at this time");
        uint256 stakedAmount = staked[msg.sender].length;
        uint256 rate = 0;
        uint delta = block.timestamp - scrapClaimEpoch[msg.sender];
        if (stakedAmount == 5) {
            rate = 550 ether;
        } else if (stakedAmount == 10) {
            rate = 1150 ether;
        }
        uint256 claimableScrap = (rate*delta)/86400;
        scrapClaimEpoch[msg.sender] = block.timestamp;
        ScrapV2.increaseScrapBalance(msg.sender, claimableScrap);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}