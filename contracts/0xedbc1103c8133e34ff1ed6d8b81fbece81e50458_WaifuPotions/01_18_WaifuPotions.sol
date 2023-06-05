// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
                                o  .      #
                                . .  .    ##
                                . O o .  ###
                              .  o  .     #
                                o O.      |
                                . o O     |/|
                                ___o_    /,,|
                                | O |   |,,,|
                                |o .|   | ,,|
                                | .o|   | , |
                                |O  |   | , |
                                | .O|   |   |
                              __|o .|__ |   |
                             / . O o  o\|   |
                            /. O .o .O .\   |
                           |^^^^^^^^^^^^^|  |
                           |             |__|_
                            \           /======
                             \_________/
         __   __  ___       __        __     _______  ____  ____  
        |"  |/  \|  "|     /""\      |" \   /"     "|("  _||_ " | 
        |'  /    \:  |    /    \     ||  | (: ______)|   (  ) : | 
        |: /'        |   /' /\  \    |:  |  \/    |  (:  |  | . ) 
         \//  /\'    |  //  __'  \   |.  |  // ___)   \\ \__/ //  
         /   /  \\   | /   /  \\  \  /\  |\(:  (      /\\ __ //\  
        |___/    \___|(___/    \___)(__\_|_)\__/     (__________) 

   _______    ______  ___________  __      ______    _____  ___    ________  
  |   __ "\  /    " \("     _   ")|" \    /    " \  (\"   \|"  \  /"       ) 
  (. |__) :)// ____  \)__/  \\__/ ||  |  // ____  \ |.\\   \    |(:   \___/  
  |:  ____//  /    ) :)  \\_ /    |:  | /  /    ) :)|: \.   \\  | \___  \    
  (|  /   (: (____/ //   |.  |    |.  |(: (____/ // |.  \    \. |  __/  \\   
 /|__/ \   \        /    \:  |    /\  |\\        /  |    \    \ | /" \   :)  
(_______)   \"_____/      \__|   (__\_|_)\"_____/    \___|\____\)(_______/   

 */

/**
 * @title Waifu Potions ERC1155 Smart Contract
 * @dev Extends ERC1155 
 */

contract WaifuPotions is ERC1155, ERC1155Supply, ERC1155Burnable, Ownable, PaymentSplitter, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private counter; 
    string _name = "Waifu Potions";
    string _symbol = "WP";
    string private _contractURI;
    address public minterAddress;   
    bool public mintIsActivePublic = false;
    bool public mintIsActiveClaim = false;

    mapping(uint256 => Potion) public potions;

    struct Potion {
        uint256 tokenPrice;
        uint256 maxTokensPerTxn;
        uint256 numMintedPublic;
        uint256 maxTokensPublic;
        bytes32 merkleRoot;
        mapping(address => bool) claimed;
    }

    constructor(address[] memory _payees, uint256[] memory _shares) ERC1155("") PaymentSplitter(_payees, _shares) payable {}

    /**
    * @notice free claim for token holders
    */
    function claim(
        uint256 potionId,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external nonReentrant {
        require(mintIsActiveClaim, "Claim is not active.");
        require(
            potions[potionId].claimed[msg.sender] == false, 
            "You already claimed this potion."
        );

        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        require(
            MerkleProof.verify(merkleProof, potions[potionId].merkleRoot, node),
            "You have a bad Merkle Proof."
        );

        potions[potionId].claimed[msg.sender] = true;

        _mint(msg.sender, potionId, amount, "");
    }

    /**
    * @notice public mint for poitions
    */
    function mint(uint256 potionId, uint256 amount) external payable nonReentrant {
        require(tx.origin == msg.sender);
        require(mintIsActivePublic, "Public mint is not active");
        require(
            amount <= potions[potionId].maxTokensPerTxn, 
            "You can't mint that many tokens per transaction."
        );
        require(
            potions[potionId].numMintedPublic + amount <= potions[potionId].maxTokensPublic, 
            "Tokens are all minted."
        );
        require(
            msg.value >= amount * potions[potionId].tokenPrice, 
            "Incorrect amount of ETH."
        );

        potions[potionId].numMintedPublic += amount;

        _mint(msg.sender, potionId, amount, "");
    }

    /**
    * @notice create a new potion
    */
    function addPotion(
        bytes32 _merkleRoot,
        uint256 _tokenPrice,
        uint256 _maxTokensPublic,
        uint256 _maxTokensPerTxn
    ) external onlyOwner {
        Potion storage p = potions[counter.current()];
        p.merkleRoot = _merkleRoot;
        p.tokenPrice = _tokenPrice;
        p.maxTokensPublic = _maxTokensPublic;
        p.maxTokensPerTxn = _maxTokensPerTxn;

        counter.increment();
    }

    /**
    * @notice edit an existing potion
    */
    function editPotion(
        uint256 _potionId,
        bytes32 _merkleRoot,
        uint256 _tokenPrice,
        uint256 _maxTokensPublic,
        uint256 _maxTokensPerTxn
    ) external onlyOwner {
        require(exists(_potionId), "");

        potions[_potionId].tokenPrice = _tokenPrice;
        potions[_potionId].maxTokensPublic = _maxTokensPublic;
        potions[_potionId].maxTokensPerTxn = _maxTokensPerTxn;
        potions[_potionId].merkleRoot = _merkleRoot;
    }

    /**
     * @notice turn on/off public mint
     */
    function flipMintStatePublic() external onlyOwner {
        mintIsActivePublic = !mintIsActivePublic;
    }

    /**
     * @notice turn on/off free claim 
     */
    function flipMintStateClaim() external onlyOwner {
        mintIsActiveClaim = !mintIsActiveClaim;
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
    *  @notice mint a batch of token collections
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
    * @notice check if wallet claimed for all potions
    */
    function checkClaimed(address wallet) external view returns (bool[] memory) {
        bool[] memory result = new bool[](counter.current());

        for(uint256 i; i < counter.current(); i++) {
            result[i] = potions[i].claimed[wallet];
        }

        return result;
    }

   /**
    * @notice indicates weither any token exist with a given id, or not
    */
    function exists(uint256 id) public view override returns (bool) {
        return potions[id].maxTokensPublic > 0;
    }

    // @title SETTER FUNCTIONS

    /**
    *  @notice set token base uri
    */
    function setURI(string memory baseURI) public onlyMinter {
        _setURI(baseURI);
    }

    /**
    *  @notice set contract uri https://docs.opensea.io/docs/contract-level-metadata
    */
    function setContractURI(string memory newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }

    /**
    *  @notice Withdraw eth from contract by wallet
    */
    function release(address payable account) public override {
        require(msg.sender == account || msg.sender == owner(), "Release: no permission");

        super.release(account);
    }

    /**
     * @notice Withdraw ETH in contract to ownership wallet
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
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