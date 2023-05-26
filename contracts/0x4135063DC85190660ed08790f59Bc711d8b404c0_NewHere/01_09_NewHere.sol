// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title We'reNewHere
 * @author maikir
 */

contract NewHere is ERC721A, ERC721AQueryable, Ownable {
    // Base URI
    string public _uri;

    //Sale states
    bool public isPreSaleFreeActive;
    bool public isPreSalePaidActive;
    bool public isPublicSaleFreeActive;
    bool public isPublicSalePaidActive;

    //Staking state
    bool public isStakingActive;

    // Merkle tree roots
    bytes32 public preSaleFreeRoot;
    bytes32 public preSalePaidRoot;
    bytes32 public publicSaleFreeRoot;

    // Max number of tokens
    uint256 public immutable MAX_SUPPLY;
    // Pre-sale free reserved supply //150
    uint256 public oneToOneAddressReserve;
    // Public sale free reserved supply (tier 3) //605
    uint256 public publicSaleFreeAllowlistReserve;
    // Dpop wallet reserved supply //50
    uint256 public dPopReserve;

    // Allowlist mint price -- 0.088 ETH
    uint256 public immutable MINT_PRICE = 88000000000000000;

    // Max number of mints per tx for public mint
    uint256 public maxNumberMintsPerTx = 5;

    uint256 public tokenCounter;

    //token URI freezer
    bool frozen = false;

    // Track allocation remaining that is allowed to be minted by pre-sale free minters
    mapping(address => int256) public preSaleFreeAllowlistQuantity;
    // Track allocation remaining that is allowed to be minted by pre-sale paid minters
    mapping(address => int256) public preSalePaidAllowlistQuantity;
    // Track allocation remaining that is allowed to be minted by public sale free minters
    mapping(address => int256) public publicSaleFreeAllowlistQuantity;

    mapping(address => bool) private admins;

    struct StakingInfo {
        address stakerAddress;
        uint64 startTime;
        uint64 totalTime;
        bool staked;
    }

    mapping(uint256 => StakingInfo) public staking;
    mapping(address => uint256) public quantityStaked;

    constructor(
        string memory _baseURI_,
        bytes32 _preSaleFreeRoot,
        bytes32 _preSalePaidRoot,
        bytes32 _publicSaleFreeRoot,
        uint256 _MAX_SUPPLY,
        uint256 _oneToOneAddressReserve,
        uint256 _publicSaleFreeAllowlistReserve,
        uint256 _dPopReserve
    ) ERC721A("NewHere", "NEWHERE") {
        _uri = _baseURI_;
        preSaleFreeRoot = _preSaleFreeRoot;
        preSalePaidRoot = _preSalePaidRoot;
        publicSaleFreeRoot = _publicSaleFreeRoot;
        MAX_SUPPLY = _MAX_SUPPLY;
        oneToOneAddressReserve = _oneToOneAddressReserve;
        publicSaleFreeAllowlistReserve = _publicSaleFreeAllowlistReserve;
        dPopReserve = _dPopReserve;
    }

    function setAdmin(address _addr, bool _status) public onlyOwner {
        admins[_addr] = _status;
    }

    modifier onlyAdmin() {
        require(owner() == msg.sender || admins[msg.sender], "No Access");
        _;
    }

    modifier canTransfer(uint256 tokenId) {
        require(
            !staking[tokenId].staked,
            "Token is currently being staked and cannot be transferred"
        );
        _;
    }

    /**
     * @dev Flips the sale state for minting.
     */
    function flipSaleState(uint256 _saleStateNum) external onlyOwner {
        if (_saleStateNum == 0) {
            isPreSaleFreeActive = !isPreSaleFreeActive;
        } else if (_saleStateNum == 1) {
            isPreSalePaidActive = !isPreSalePaidActive;
        } else if (_saleStateNum == 2) {
            isPublicSaleFreeActive = !isPublicSaleFreeActive;
        } else if (_saleStateNum == 3) {
            isPublicSalePaidActive = !isPublicSalePaidActive;
        }
    }

    /**
     * @dev Flips the staking state for staking.
     */
    function flipStakingState() external onlyOwner {
        isStakingActive = !isStakingActive;
    }

    /**
     * @dev Merkle tree for the pre-sale free allowlist.
     */
    function setMerkleTreePreSaleFreeAllowlist(
        bytes32 _preSaleFreeRoot,
        uint256 _preSaleFreeAllowlistReserveUpdate,
        uint256 _add_sub
    )
        external
        onlyOwner
    {
        preSaleFreeRoot = _preSaleFreeRoot;
        if (_add_sub == 0) {
            require(
                _add_sub <= oneToOneAddressReserve,
                "Subtracting amount is greater than the current reserve amount"
            );
            oneToOneAddressReserve -= _preSaleFreeAllowlistReserveUpdate;
        } else if (_add_sub == 1) {
            oneToOneAddressReserve += _preSaleFreeAllowlistReserveUpdate;
        }
    }

    /**
     * @dev Merkle tree for the pre-sale paid allowlist.
     */
    function setMerkleTreePreSalePaidAllowlist(bytes32 _preSalePaidRoot)
        external
        onlyOwner
    {
        preSalePaidRoot = _preSalePaidRoot;
    }

    /**
     * @dev Merkle tree for the public sale free allowlist.
     */
    function setMerkleTreePublicSaleFreeAllowlist(
        bytes32 _publicSaleFreeRoot,
        uint256 _publicSaleFreeAllowlistReserveUpdate,
        uint256 _add_sub
    )
        external
        onlyOwner
    {
        publicSaleFreeRoot = _publicSaleFreeRoot;
        if (_add_sub == 0) {
            require(
                _add_sub <= publicSaleFreeAllowlistReserve,
                "Subtracting amount is greater than the current reserve amount"
            );
            publicSaleFreeAllowlistReserve -= _publicSaleFreeAllowlistReserveUpdate;
        } else if (_add_sub == 1) {
            publicSaleFreeAllowlistReserve += _publicSaleFreeAllowlistReserveUpdate;
        }
    }

    /**
     * @dev Function called to return if an address is allowlisted.
     * @param proof Merkel tree proof.
     * @param _address Address to check.
     * @param _merkleTreeNum Merkle tree number to check.
     */
    function isAllowlisted(
        bytes32[] calldata proof,
        address _address,
        uint256 _merkleTreeNum
    ) public view returns (bool) {
        require(
            _merkleTreeNum == 0 || _merkleTreeNum == 1 || _merkleTreeNum == 2,
            "Merkle tree number is not valid"
        );

        bytes32 root;

        if (_merkleTreeNum == 0) {
            root = preSaleFreeRoot;
        } else if (_merkleTreeNum == 1) {
            root = preSalePaidRoot;
        } else if (_merkleTreeNum == 2) {
            root = publicSaleFreeRoot;
        }

        if (
            MerkleProof.verify(
                proof,
                root,
                keccak256(abi.encodePacked(_address))
            )
        ) {
            return true;
        }
        return false;
    }

    /**
     * @dev Free allowlist minting function for pre-sale. Default maximum of 1 free mint per user.
     * @param proof Merkel tree proof.
     * @param quantity Quantity to mint.
     */
    function mintPreSaleFreeAllowlist(bytes32[] calldata proof, int256 quantity)
        external
    {
        require(isPreSaleFreeActive, "Free pre-sale must be active");
        require(
            isAllowlisted(proof, msg.sender, 0),
            "Caller not pre-sale free allowlisted"
        );
        require(quantity > 0, "Quantity must be a postitive number");
        require(
            quantity <= preSaleFreeAllowlistQuantity[msg.sender] + 1,
            "Minting quantity exceeds allocation left for user"
        );
        require(
            tokenCounter + uint256(quantity) <=
                (MAX_SUPPLY - dPopReserve - publicSaleFreeAllowlistReserve),
            "Token count exceeds limit for pre-sale free allowlist"
        );
        _safeMint(msg.sender, uint256(quantity));
        preSaleFreeAllowlistQuantity[msg.sender] -= quantity;
        oneToOneAddressReserve -= uint256(quantity);
        tokenCounter += uint256(quantity);
    }

    /**
     * @dev Paid allowlist minting function for pre-sale. Default maximum of 2 paid mints per user.
     * @param proof Merkel tree proof.
     * @param quantity Quantity to mint.
     */
    function mintPreSalePaidAllowlist(bytes32[] calldata proof, int256 quantity)
        external
        payable
    {
        require(isPreSalePaidActive, "Paid pre-sale must be active");
        require(
            isAllowlisted(proof, msg.sender, 1),
            "Caller not pre-sale paid allowlisted"
        );
        require(quantity > 0, "Quantity must be a postitive number");
        require(
            quantity <= preSalePaidAllowlistQuantity[msg.sender] + 2,
            "Minting quantity exceeds allocation left for user"
        );
        require(
            tokenCounter + uint256(quantity) <=
                (MAX_SUPPLY -
                    dPopReserve -
                    publicSaleFreeAllowlistReserve -
                    oneToOneAddressReserve),
            "Token count exceeds limit for pre-sale paid allowlist"
        );
        require(
            msg.value >= (MINT_PRICE * uint256(quantity)),
            "Ether value sent is incorrect"
        );
        _safeMint(msg.sender, uint256(quantity));
        preSalePaidAllowlistQuantity[msg.sender] -= quantity;
        tokenCounter += uint256(quantity);
    }

    /**
     * @dev Free allowlist minting function for public sale. Default maximum of 1 free mint per user.
     * @param proof Merkel tree proof.
     * @param quantity Quantity to mint.
     */
    function mintPublicSaleFreeAllowlist(
        bytes32[] calldata proof,
        int256 quantity
    ) external {
        require(isPublicSaleFreeActive, "Free public sale must be active");
        require(
            isAllowlisted(proof, msg.sender, 2),
            "Caller not public sale free allowlisted"
        );
        require(quantity > 0, "Quantity must be a postitive number");
        require(
            quantity <= publicSaleFreeAllowlistQuantity[msg.sender] + 1,
            "Minting quantity exceeds allocation left for user"
        );
        require(
            tokenCounter + uint256(quantity) <= (MAX_SUPPLY - dPopReserve - oneToOneAddressReserve),
            "Token count exceeds limit for public sale free allowlist"
        );
        _safeMint(msg.sender, uint256(quantity));
        publicSaleFreeAllowlistQuantity[msg.sender] -= quantity;
        publicSaleFreeAllowlistReserve -= uint256(quantity);
        tokenCounter += uint256(quantity);
    }

    /**
     * @dev Minting function.
     * @param quantity Quantity to mint.
     */
    function mintPublicSale(uint256 quantity) external payable {
        require(isPublicSalePaidActive, "Paid public sale must be active");
        require(
            quantity <= maxNumberMintsPerTx,
            "Quantity is larger than the allowed number of mints in one transaction"
        );
        require(
            msg.value >= (MINT_PRICE * quantity),
            "Ether value sent is incorrect"
        );
        require(
            tokenCounter + quantity <=
                (MAX_SUPPLY -
                    dPopReserve -
                    publicSaleFreeAllowlistReserve -
                    oneToOneAddressReserve),
            "Token count exceeds limit for public sale paid"
        );
        _safeMint(msg.sender, quantity);
        tokenCounter += quantity;
    }

    /**
     * @dev Minting function reserved for dpop wallet.
     * @param _address Address to mint to.
     * @param quantity Quantity to mint.
     */
    function dpopMint(address _address, uint256 quantity) external onlyAdmin {
        require(
            quantity <= dPopReserve,
            "Quantity exceeds allocation left for dpop wallet"
        );
        require(tokenCounter + quantity <= MAX_SUPPLY, "Token count exceeds limit for dpop wallet");
        _safeMint(_address, quantity);
        dPopReserve -= quantity;
        tokenCounter += quantity;
    }

    /**
     * @dev Admin mint function.
     * @param _address Address to mint to.
     * @param quantity Quantity to mint.
     */
    function adminMint(address _address, uint256 quantity) external onlyAdmin {
        require(tokenCounter + quantity <= MAX_SUPPLY, "Token count exceeds limit for admin function");
        _safeMint(_address, quantity);
        tokenCounter += quantity;
    }

    /**
     * @dev Sets maximum number of mints in a single tx per caller for normal mint function.
     */
    function setMaxNumberMintsPerTx(uint256 _maxNumberMintsPerTx)
        external
        onlyOwner
    {
        maxNumberMintsPerTx = _maxNumberMintsPerTx;
    }

    /**
     * @dev Staking function.
     * @param quantity Quantity to stake.
     * @param tokenIds Token ids to stake.
     */
    function stake(uint256 quantity, uint256[] calldata tokenIds) external {
        require(isStakingActive, "Staking must be active");
        require(
            quantity == tokenIds.length,
            "Quantity does not match up with size of token ids"
        );
        require(
            quantityStaked[msg.sender] + quantity <= balanceOf(msg.sender),
            "Quantity exceeds numbers of tokens held by sender available for staking"
        );

        uint64 currentTime = uint64(block.timestamp);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                ownerOf(tokenIds[i]) == msg.sender,
                "Staker is not the owner of the token trying to be staked"
            );
            require(
                !staking[tokenIds[i]].staked,
                "Token is already being staked"
            );
            staking[tokenIds[i]].stakerAddress = msg.sender;
            staking[tokenIds[i]].startTime = currentTime;
            staking[tokenIds[i]].staked = true;
        }
        quantityStaked[msg.sender] += quantity;
    }

    /**
     * @dev Unstaking function.
     * @param quantity Quantity to unstake.
     * @param tokenIds Token ids to unstake.
     */
    function unstake(uint256 quantity, uint256[] calldata tokenIds) external {
        require(isStakingActive, "Staking must be active");
        require(
            quantity == tokenIds.length,
            "Quantity does not match up with size of token ids"
        );
        require(
            quantityStaked[msg.sender] >= quantity,
            "Quantity is larger than the amount of tokens being staked"
        );

        uint64 currentTime = uint64(block.timestamp);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                ownerOf(tokenIds[i]) == msg.sender,
                "Staker is not the owner of the token trying to be unstaked"
            );
            require(
                staking[tokenIds[i]].staked,
                "Token is not currently being staked"
            );
            uint64 prevStartTime = staking[tokenIds[i]].startTime;
            staking[tokenIds[i]].totalTime += (currentTime - prevStartTime);
            staking[tokenIds[i]].stakerAddress = address(0);
            staking[tokenIds[i]].startTime = 0;
            staking[tokenIds[i]].staked = false;
        }
        quantityStaked[msg.sender] -= quantity;
    }

    /**
     * @dev Sets the pre-sale free allowlist quantities. Default maximum of 1 free mint per user.
     * @param addresses The addresses to set for the allowlist.
     * @param quantities The quantities for each address to be able to mint in the allowlist.
     */
    function setPreSaleFreeAllowlist(
        address[] calldata addresses,
        int256[] calldata quantities
    ) external onlyOwner {
        require(
            addresses.length == quantities.length,
            "Addresses and quantities lengths do not match up"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            preSaleFreeAllowlistQuantity[addresses[i]] = (quantities[i] - 1);
        }
    }

    /**
     * @dev Sets the pre-sale paid allowlist quantities. Default maximum of 2 paid mints per user.
     * @param addresses The addresses to set for the allowlist.
     * @param quantities The quantities for each address to be able to mint in the allowlist.
     */
    function setPreSalePaidAllowlist(
        address[] calldata addresses,
        int256[] calldata quantities
    ) external onlyOwner {
        require(
            addresses.length == quantities.length,
            "Addresses and quantities lengths do not match up"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            preSalePaidAllowlistQuantity[addresses[i]] = (quantities[i] - 2);
        }
    }

    /**
     * @dev Sets the public sale free allowlist quantities. Default maximum of 1 free mint per user.
     * @param addresses The addresses to set for the allowlist.
     * @param quantities The quantities for each address to be able to mint in the allowlist.
     */
    function setPublicSaleFreeAllowlist(
        address[] calldata addresses,
        int256[] calldata quantities
    ) external onlyOwner {
        require(
            addresses.length == quantities.length,
            "Addresses and quantities lengths do not match up"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            publicSaleFreeAllowlistQuantity[addresses[i]] = (quantities[i] - 1);
        }
    }

    /**
     * @dev Getter for the number of quantities left for various allowlists.
     * @param _address Address to lookup.
     * @param _allowlistNum Number specifying which allowlist to lookup.
     */
    function getAllowlistQuantities(address _address, uint256 _allowlistNum)
        external
        view
        returns (int256)
    {
        if (_allowlistNum == 0) {
            return preSaleFreeAllowlistQuantity[_address] + 1;
        } else if (_allowlistNum == 1) {
            return preSalePaidAllowlistQuantity[_address] + 2;
        } else if (_allowlistNum == 2) {
            return publicSaleFreeAllowlistQuantity[_address] + 1;
        } else {
            return -1;
        }
    }

    /**
     * @dev Allows owner to set the baseURI dynamically.
     * @param uri The base uri for the metadata store.
     */
    function setBaseURI(string memory uri) external onlyOwner {
        if (!frozen) {
            _uri = uri;
        }
    }

    /**
     * @dev One way function. Freezes the uri state of the contract.
     */
    function freeze() external onlyOwner {
        frozen = true;
    }

    /**
     * @dev Owner can withdraw funds.
     */
    function withdraw() external onlyAdmin {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev Override for allowing setting of a base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    /**
     * @dev Override _beforeTokenTransfers.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override canTransfer(startTokenId) {}
}