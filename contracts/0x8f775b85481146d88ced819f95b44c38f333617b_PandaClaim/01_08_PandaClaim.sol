/*
 **                                                                                                                                                              
 **                                                                   dddddddd                                                                                   
 **  PPPPPPPPPPPPPPPPP                                                d::::::d                  DDDDDDDDDDDDD                  AAA                 OOOOOOOOO     
 **  P::::::::::::::::P                                               d::::::d                  D::::::::::::DDD              A:::A              OO:::::::::OO   
 **  P::::::PPPPPP:::::P                                              d::::::d                  D:::::::::::::::DD           A:::::A           OO:::::::::::::OO 
 **  PP:::::P     P:::::P                                             d:::::d                   DDD:::::DDDDD:::::D         A:::::::A         O:::::::OOO:::::::O
 **    P::::P     P:::::Paaaaaaaaaaaaa  nnnn  nnnnnnnn        ddddddddd:::::d   aaaaaaaaaaaaa     D:::::D    D:::::D       A:::::::::A        O::::::O   O::::::O
 **    P::::P     P:::::Pa::::::::::::a n:::nn::::::::nn    dd::::::::::::::d   a::::::::::::a    D:::::D     D:::::D     A:::::A:::::A       O:::::O     O:::::O
 **    P::::PPPPPP:::::P aaaaaaaaa:::::an::::::::::::::nn  d::::::::::::::::d   aaaaaaaaa:::::a   D:::::D     D:::::D    A:::::A A:::::A      O:::::O     O:::::O
 **    P:::::::::::::PP           a::::ann:::::::::::::::nd:::::::ddddd:::::d            a::::a   D:::::D     D:::::D   A:::::A   A:::::A     O:::::O     O:::::O
 **    P::::PPPPPPPPP      aaaaaaa:::::a  n:::::nnnn:::::nd::::::d    d:::::d     aaaaaaa:::::a   D:::::D     D:::::D  A:::::A     A:::::A    O:::::O     O:::::O
 **    P::::P            aa::::::::::::a  n::::n    n::::nd:::::d     d:::::d   aa::::::::::::a   D:::::D     D:::::D A:::::AAAAAAAAA:::::A   O:::::O     O:::::O
 **    P::::P           a::::aaaa::::::a  n::::n    n::::nd:::::d     d:::::d  a::::aaaa::::::a   D:::::D     D:::::DA:::::::::::::::::::::A  O:::::O     O:::::O
 **    P::::P          a::::a    a:::::a  n::::n    n::::nd:::::d     d:::::d a::::a    a:::::a   D:::::D    D:::::DA:::::AAAAAAAAAAAAA:::::A O::::::O   O::::::O
 **  PP::::::PP        a::::a    a:::::a  n::::n    n::::nd::::::ddddd::::::dda::::a    a:::::a DDD:::::DDDDD:::::DA:::::A             A:::::AO:::::::OOO:::::::O
 **  P::::::::P        a:::::aaaa::::::a  n::::n    n::::n d:::::::::::::::::da:::::aaaa::::::a D:::::::::::::::DDA:::::A               A:::::AOO:::::::::::::OO 
 **  P::::::::P         a::::::::::aa:::a n::::n    n::::n  d:::::::::ddd::::d a::::::::::aa:::aD::::::::::::DDD A:::::A                 A:::::A OO:::::::::OO   
 **  PPPPPPPPPP          aaaaaaaaaa  aaaa nnnnnn    nnnnnn   ddddddddd   ddddd  aaaaaaaaaa  aaaaDDDDDDDDDDDDD   AAAAAAA                   AAAAAAA  OOOOOOOOO     
 **  
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract PandaClaim is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    
    address public immutable pandaToken;
    address public usdToken;
    mapping(address => uint256) public claimRecord;
    mapping(address => uint256) public pandaClaimSum;
    mapping(address => uint256) public usdClaimSum;
    mapping(address => uint256) public etherClaimSum;
    uint256 public claimCycle;
    bool public claimOpen;
    // bytes32 public merkleRoot;
    bytes32 public merkleRoot;
    uint256 public totalClaimPanda;
    uint256 public totalClaimUsd;
    uint256 public totalClaimEth;

    address public constant ZERO_ADDRESS = address(0);

    event MerkleRootChanged(bytes32 merkleRoot);
    event UsdTokenChanged(address usdToken);
    event ClaimPanda(address indexed claimant, uint256 amount, uint256 sumAmount, uint256 etherAmount, uint256 etherSumAmount, uint256 usdAmount, uint256 usdSumAmount);
    event WithdrawERC20(address recipient, address tokenAddress, uint256 tokenAmount);
    event WithdrawEther(address recipient, uint256 amount);
    event ClaimOpenChange(bool open);

    /**
     * ErrorCode:
     * PE1:PandaDAO:Zero address
     * PE2:PandaDAO:claim zore tokens!
     * PE3:PandaDAO:same _merkleRoot
     * PE4:PandaDAO:same usd Token!
     * PE5:PandaDAO:Valid claimCycle required.
     * PE6:PandaDAO:PandaCliam dont have enough $PANDA.
     * PE7:PandaDAO:Valid panda proof required.
     * PE8:PandaDAO:PandaDAO:claim close!
     * PE9:PandaDAO:transfer ether fail!
     * PE10:PandaDAO:invalid arguements
     * PE11:PandaDAO:withdrawEther fail!
     * PE12:PandaDAO: PandaDAO:claim open same
     * PE13:PandaDAO:PandaCliam dont have enough $ETH.
     * PE14:PandaDAO:PandaCliam dont have enough $USD.
     */

    modifier notZeroAddr(address addr_) {
        require(addr_ != ZERO_ADDRESS, "PE1");
        _;
    }



    /**
     * @dev Constructor.
     */
    constructor(
        address _pandaToken,
        address _usdToken
    )
    {
        pandaToken = _pandaToken;
        usdToken = _usdToken;
    }


    /**
     * @dev Claims  tokens.
     * @param amount The amount of panda.
     * @param etherAmount The amount of ether.
     * @param usdAmount The amount of usd.
     * @param merkleProof A merkle proof proving the claim is valid.
     */
    function claimPandaTokens(uint256 amount, uint256 etherAmount, uint256 usdAmount, bytes32[] calldata merkleProof) external nonReentrant {
        require(claimOpen, "PE8");
        //claimCycle check
        require(claimRecord[msg.sender] < claimCycle, "PE5");
        require(amount + etherAmount + usdAmount > 0, "PE2");

        //balance check
        require(IERC20(pandaToken).balanceOf(address(this)) >= amount, "PE6");
        require(address(this).balance >= etherAmount, "PE13");
        require(IERC20(usdToken).balanceOf(address(this)) >= usdAmount, "PE14");
        //merkle check
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount, etherAmount, usdAmount));
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        require(valid, "PE7");
        //update claimCycle
        claimRecord[msg.sender] = claimCycle;

        //transfer token
        if(amount > 0) {
            IERC20(pandaToken).safeTransfer(msg.sender, amount);
        }
        if (etherAmount > 0) {
            (bool success,) = msg.sender.call{value:etherAmount}("");
            require(success, "PE9");
        }
        if (usdAmount > 0) {
            IERC20(usdToken).safeTransfer(msg.sender, usdAmount);
        }
        
        pandaClaimSum[msg.sender] += amount;
        etherClaimSum[msg.sender] += etherAmount;
        usdClaimSum[msg.sender] += usdAmount;
        totalClaimPanda += amount;
        totalClaimEth += etherAmount;
        totalClaimUsd += usdAmount;
        emit ClaimPanda(msg.sender, amount, pandaClaimSum[msg.sender], etherAmount, etherClaimSum[msg.sender], usdAmount, usdClaimSum[msg.sender]);
    }




    /**
     * @dev Sets the merkle root. Only callable if the root is not yet set.
     * @param _merkleRoot tokens claim merkle tree.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        claimCycle++;
        emit MerkleRootChanged(_merkleRoot);
    }

    /**
     * @dev update the merkle root.
     * @param _merkleRoot tokens claim merkle tree.
     */
    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require(merkleRoot != _merkleRoot, "PE3");
        merkleRoot = _merkleRoot;
        emit MerkleRootChanged(_merkleRoot);
    }

    /**
     * @dev set Usd Token Address
     * @param _token token address
     */
    function setUsdToken(address _token) external onlyOwner notZeroAddr(_token) {
        require(usdToken != _token, "PE4");
        usdToken = _token;
        emit UsdTokenChanged(_token);
    }

    /**
     * @dev set claim open ro not
     * @param _open true or false
     */
    function setClaimOpen(bool _open) external onlyOwner {
        require(_open != claimOpen, "PE12");
        claimOpen = _open;
        emit ClaimOpenChange(_open);
    }


    /**
     * @dev withdrawERC20  tokens.
     * @param recipient recipient
     * @param tokenAddress  token
     * @param tokenAmount amount
     */
    function withdrawERC20(
        address recipient,
        address tokenAddress, 
        uint256 tokenAmount
    ) external onlyOwner notZeroAddr(tokenAddress) 
    {
        IERC20(tokenAddress).safeTransfer(recipient, tokenAmount);

        emit WithdrawERC20(recipient, tokenAddress, tokenAmount);
    }

    

    /**
     * @dev withdraw Ether.
     * @param recipient recipient
     * @param amount amount
     */
    function withdrawEther(address payable recipient, uint256 amount) external onlyOwner {
        (bool success,) = recipient.call{value:amount}("");
        require(success, "PE11");
        emit WithdrawEther(recipient, amount);
    }

    fallback () external payable {}

    receive () external payable {}


}