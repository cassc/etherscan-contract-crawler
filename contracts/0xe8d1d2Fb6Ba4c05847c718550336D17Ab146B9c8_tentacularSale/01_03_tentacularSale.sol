// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import {SecuredBase} from "../src/base/SecuredBase.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface ITentacular {
    function mint(address wallet, uint amount) external;
}

contract tentacularSale is SecuredBase {
    ITentacular tentacularContract;

    uint public publicSalePrice;
    uint public alSalePrice;
    uint public maxPerWallet = 3;

    uint public alAndPublicReserve = 5000;
    uint public alAndPublicMinted;

    uint public freeMintReserve = 400;
    uint public freeMinted;

    uint public teamReserve = 156;
    uint public teamMinted;

    error WrongValueSent();
    error WrongProof();
    error PublicSaleTurnedOff();
    error AlSaleTurnedOff();
    error MaxPerWalletExceed();
    error FreeMintUsed();
    error ReserveExceed();
    error SendValueFailed(address);

    bool public alSaleLive=false;
    bool public publicSaleLive=false;

    bytes32 ALMerkleRoot;
    bytes32 FreeMintMerkleRoot;

    mapping(address => uint[2]) walletToMinted; // [0] - public and AL minted, [1] - free minted

    constructor() {}
    
    ////////////////////////////////////////////////////////////////////////////////
    //// USER ACTIONS
    ////////////////////////////////////////////////////////////////////////////////

    /** 
    @dev mint count of tokens with the public sale price
    @notice can be called only when public sale is active
    @param count count of tokens to be minted
    */
    function publicSale(uint count) external payable noContracts OnlyPublicSaleLive {
        if (msg.value < publicSalePrice*count) revert WrongValueSent();
        if (alAndPublicMinted + count > alAndPublicReserve) revert ReserveExceed();
        
        uint[2] storage mintedNumbers = walletToMinted[msg.sender];
        if (mintedNumbers[0] + mintedNumbers[1] + count > maxPerWallet) revert MaxPerWalletExceed();

        mintedNumbers[0] += count;
        alAndPublicMinted += count;

        tentacularContract.mint(msg.sender, count);
    }

    /** 
    @dev mint count of tokens with the AL price
    @notice can be called onl when AL sale is active
    @param count count of tokens to be minted
    @param proof merkle proof
    */
    function alSale(uint count, bytes32[] calldata proof) external payable noContracts OnlyAlSaleLive {
        if (MerkleProof.verify(proof, ALMerkleRoot, keccak256(abi.encodePacked(msg.sender)))==false) revert WrongProof();
        if (msg.value < alSalePrice*count) revert WrongValueSent();
        if (alAndPublicMinted + count > alAndPublicReserve) revert ReserveExceed();

        uint[2] storage mintedNumbers = walletToMinted[msg.sender];
        if (mintedNumbers[0] + mintedNumbers[1] + count > maxPerWallet) revert MaxPerWalletExceed();

        mintedNumbers[0]+=count;
        alAndPublicMinted+=count;

        tentacularContract.mint(msg.sender, count);
    }

    /** 
    @dev mint count of tokens with the AL price
    @notice can be called only when AL sale is active
    @param proof merkle proof
    */
    function freeMint(bytes32[] calldata proof) external noContracts OnlyAlSaleLive {
        if (MerkleProof.verify(proof, FreeMintMerkleRoot, keccak256(abi.encodePacked(msg.sender)))==false) revert WrongProof();
        if (freeMinted >= freeMintReserve) revert ReserveExceed();

        uint[2] storage mintedNumbers = walletToMinted[msg.sender];
        if (mintedNumbers[1] > 0) revert FreeMintUsed();
        if (mintedNumbers[0] + mintedNumbers[1] >= maxPerWallet) revert MaxPerWalletExceed();

        mintedNumbers[1]=1;
        freeMinted+=1;

        tentacularContract.mint(msg.sender, 1);
    }

    ////////////////////////////////////////////////////////////////////////////////
    //// OWNER ONLY
    ////////////////////////////////////////////////////////////////////////////////

    /** 
    @dev set reserves max capacity
    @notice total capacity should be equal to 5556 (total mints possible)
    @param _alAndPublicReserve allowlist and public sale reserve
    @param _freeMintReserve free mint capacity
    @param _teamReserve team reserve capacity
    */
    function setReservesCapacity(uint _alAndPublicReserve, uint _freeMintReserve, uint _teamReserve) external onlyOwner {
        if (_alAndPublicReserve + _freeMintReserve + _teamReserve != 5556) revert();
        alAndPublicReserve=_alAndPublicReserve;
        freeMintReserve=_freeMintReserve;
        teamReserve=_teamReserve;
    }

    /** 
    @dev reduce free mint and public/al sale reserves to amount already minted, increase the team reserve for the same amount
    */
    function moveUnmitedToTeamReserve() external onlyOwner {
        teamReserve+=(alAndPublicReserve-alAndPublicMinted)+(freeMintReserve-freeMinted);
        freeMintReserve=freeMinted;
        alAndPublicReserve=alAndPublicMinted;
    }

    /** 
    @dev mint tokens from team reserve to specified wallet
    @param wallet wallet to receive tokens
    @param count count of tokens to be minted
    */
    function mintTeamReserve(address wallet, uint count) external onlyOwner {
        if (teamMinted + count > teamReserve) revert ReserveExceed();
        teamMinted += count;
        tentacularContract.mint(wallet, count);
    }

    /** 
    @dev set AL merkle root
    @param root merkle root
    */
    function setALMerkleRoot(bytes32 root) external onlyOwner {
        ALMerkleRoot=root;
    }

    /** 
    @dev set free mint merkle root
    @param root merkle root
    */
    function setFreeMintMerkleRoot(bytes32 root) external onlyOwner {
        FreeMintMerkleRoot=root;
    }

    /** 
    @dev set all sales prices 
    @param _publicSale public sale price
    @param _alSale AL sale price
    */
    function setPrices(uint _publicSale, uint _alSale) external onlyOwner {
        publicSalePrice=_publicSale;
        alSalePrice=_alSale;
    }

    /** 
    @dev set max tokens that can be minted per wallet
    @notice same for all sales types
    @param _maxPerWallet amount can be minted by every single wallet
    */
    function setMaxPerWallet(uint _maxPerWallet) external onlyOwner {
        maxPerWallet=_maxPerWallet;
    }

    /** 
    @dev set AL sales status
    @param status true to enable, false to disable
    */
    function switchALSale(bool status) external onlyOwner {
        alSaleLive=status;
    }

    /** 
    @dev set public sale status
    @param status true to enable, false to disable
    */
    function switchPublicSale(bool status) external onlyOwner {
        publicSaleLive=status;
    }

    /** 
    @dev set Tentacular contract address
    @param _tentacularAddress address of Tentacular contract
    */
    function setTentacularContract(address _tentacularAddress) external onlyOwner {
        tentacularContract=ITentacular(_tentacularAddress);
    }

    /** 
    @dev withdraw funds
    */
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Nothing to withdraw");
        uint share = address(this).balance*40/100;
        
        (bool success, ) = payable(0x18EBfFD933175c1335d4c2FBF30CF5897469e79E).call{value: share}("");
        if (!success) revert SendValueFailed(0x18EBfFD933175c1335d4c2FBF30CF5897469e79E);

        (success, ) = payable(owner).call{value: address(this).balance}("");
        if (!success) revert SendValueFailed(owner);
    }

    ////////////////////////////////////////////////////////////////////////////////
    //// PUBLIC VIEW FUNCTIONS
    ////////////////////////////////////////////////////////////////////////////////

    function isInALMerkleTree(address wallet, bytes32[] memory proof) external view returns(bool) {
        return MerkleProof.verify(proof, ALMerkleRoot, keccak256(abi.encodePacked(wallet)));
    }

    function isInFreeMerkleTree(address wallet, bytes32[] memory proof) external view returns(bool) {
        return MerkleProof.verify(proof, FreeMintMerkleRoot, keccak256(abi.encodePacked(wallet)));
    }

    function getMintedByWallet(address wallet) external view returns(uint[2] memory) {
        return walletToMinted[wallet];
    }

    ////////////////////////////////////////////////////////////////////////////////
    //// MODIFIERS
    ////////////////////////////////////////////////////////////////////////////////

    /** 
    @dev allow method to be executed only if alSaleLive
    */
    modifier OnlyAlSaleLive {
        if (alSaleLive==false) revert AlSaleTurnedOff();
        _;
    }

    /** 
    @dev allow method to be executed only if publicSaleLive
    */
    modifier OnlyPublicSaleLive {
        if (publicSaleLive==false) revert PublicSaleTurnedOff();
        _;
    }
}