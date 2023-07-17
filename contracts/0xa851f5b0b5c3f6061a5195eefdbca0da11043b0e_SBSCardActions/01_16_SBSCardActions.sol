// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *   (        (      (           (        *           (       )  
 *   )\ )  (  )\ )   )\ )        )\ )   (  `    (     )\ ) ( /(  
 *   (()/(( )\(()/(  (()/((   (  (()/(   )\))(   )\   (()/( )\()) 
 *   /(_))((_)/(_))  /(_))\  )\  /(_)) ((_)()((((_)(  /(_)|(_)\  
 *   (_))((_)_(_))   (_))((_)((_)(_))   (_()((_)\ _ )\(_))  _((_) 
 *   / __|| _ ) __|  | _ \ __| __| |    |  \/  (_)_\(_) __|| || | 
 *   \__ \| _ \__ \  |  _/ _|| _|| |__  | |\/| |/ _ \ \__ \| __ | 
 *   |___/|___/___/  |_| |___|___|____| |_|  |_/_/ \_\|___/|_||_| 
 */

/**
 * @title SBS Card Actions ERC1155 Smart Contract only accepting $APE coin
 * @dev Extends ERC1155 
 */

contract SBSCardActions is ERC1155, ERC1155Supply, ERC1155Burnable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter private counter;
    address public tokenContract = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;

    string _name = "SBS Card Actions";
    string _symbol = "SBSCA";
    string private _contractURI;
    address public minterAddress;
    bool public mintIsActive = false;

    mapping(uint256 => Action) public actions;

    struct Action {
        uint256 tokenPrice;
        uint256 maxTokensPerTxn;
        uint256 maxTokens; 
    }

    constructor() ERC1155("") {}

    /**
    * @notice public mint for card actions
    */
    function mintAction(uint256 tokenId, uint256 qty) external nonReentrant {
        require(tx.origin == msg.sender);
        uint256 apeBalance = IERC20(tokenContract).balanceOf(msg.sender);
        require(actions[tokenId].tokenPrice * qty <= apeBalance, "Not enough $APE to mint.");
        require(mintIsActive, "Public mint is not active");
        require(
            qty <= actions[tokenId].maxTokensPerTxn, 
            "You can't mint that many tokens per transaction."
        );
        require(
            totalSupply(tokenId) + qty <= actions[tokenId].maxTokens, 
            "Tokens are all minted."
        );

        IERC20(tokenContract).safeTransferFrom(msg.sender, address(this), actions[tokenId].tokenPrice * qty);
        _mint(msg.sender, tokenId, qty, "");
    }

    /**
    * @notice create a new card action
    */
    function addAction(
        uint256 _tokenPrice,
        uint256 _maxTokens,
        uint256 _maxTokensPerTxn
    ) external onlyOwner {
        Action storage p = actions[counter.current()]; 
        p.tokenPrice = _tokenPrice;
        p.maxTokens = _maxTokens;
        p.maxTokensPerTxn = _maxTokensPerTxn;

        counter.increment();
    }

    /**
    * @notice edit an existing card action
    */
    function editAction(
        uint256 _actionId,
        uint256 _tokenPrice,
        uint256 _maxTokens,
        uint256 _maxTokensPerTxn
    ) external onlyOwner {
        require(exists(_actionId), "");

        actions[_actionId].tokenPrice = _tokenPrice;
        actions[_actionId].maxTokens = _maxTokens;
        actions[_actionId].maxTokensPerTxn = _maxTokensPerTxn;
    }

    /**
     * @notice turn on/off public mint
     */
    function flipMintState() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    /**
    *  @notice set address of minter for airdrops
    */
    function setMinterAddress(address minter) public onlyOwner {
	    minterAddress = minter;
    }

    modifier onlyMinter {
	    require(minterAddress == msg.sender || owner() == msg.sender, "You must have the Minter role");
	    _;
    }

    /**
    *  @notice mint a collection
    */
    function mintReserve(uint256 tokenId, uint256 amount) public onlyOwner {
        _mint(msg.sender, tokenId, amount, "");
    }

    /**
    *  @notice mint a batch of token collections for airdrops
    */
    function mintBatch(
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyMinter {
        _mintBatch(msg.sender, ids, amounts, "");
    }

    /**
    *  @notice mint a collection to a wallet
    */
    function mintToWallet(address toWallet, uint256 tokenId, uint256 amount) public onlyOwner {
        _mint(toWallet, tokenId, amount, "");
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function contractURI() public view returns (string memory) {
	    return _contractURI;
    }

    /**
    * @notice erc20 token balance of contract address
    */
    function getContractTokenBalance() public onlyOwner view returns(uint256){
       return IERC20(tokenContract).balanceOf(address(this));
    }

    /**
    * @notice does token exist
    */
    function exists(uint256 id) public view override returns (bool) {
        return actions[id].maxTokens > 0;
    }

    // @title SETTER FUNCTIONS

    /**
    *  @notice set token base uri
    */
    function setURI(string memory baseURI) public onlyOwner {
        _setURI(baseURI);
    }

    /**
    *  @notice set token contract for erc20
    */
    function setTokenAddress(address token) public onlyOwner {
        tokenContract = token;
    }

     /**
    *  @notice set contract uri https://docs.opensea.io/docs/contract-level-metadata
    */
    function setContractURI(string memory newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }

    /**
     * @notice Withdraw $APE and ETH in contract to ownership wallet
     */ 
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if(balance > 0){
            Address.sendValue(payable(owner()), balance);
        }

        balance = IERC20(tokenContract).balanceOf(address(this));
        if(balance > 0){
            IERC20(tokenContract).safeTransfer(owner(), balance);
        }
    }

     /**
     * @notice Withdraw $APE in contract to ownership wallet - only use as backup
     */
    function withdrawAPE(uint256 amount) external onlyOwner {
        IERC20(tokenContract).safeTransfer(owner(), amount);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

}