// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
    ERC1155 Smart Contract - JUNIQUE POP Genesis Collection

    Besitzer einer JUNIQUE Tasche bzw. JUNIQUE NFTs erhalten keine Exklusivrechte/Ownership an den verwendeten NFTs und an der verwendeten Musik.

*/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

/// @custom:security-contact [email protected]
contract JUNIQUE_POP_Genesis_Collection is ERC1155, AccessControl, ERC1155Burnable,Pausable, ERC1155Supply, PaymentSplitter {

    using Counters for Counters.Counter;

    uint public constant NUMBER_RESERVED_TOKENS = 500;
    uint256 public price = 275000000000000000; // The initial price to mint in WEI.
    uint256 public discount = 0;

    mapping(uint256 => uint256) public tokenMaxSupply; // 0 is openEnd
    mapping(uint256 => uint256) public perWalletMaxTokens; // 0 is openEnd
    mapping(address => mapping(uint256 => uint256)) public mintCount;

    bytes32 public merkleRoot;
    address public discountContract = 0x0000000000000000000000000000000000000000;
    bytes4 public discountOwnerFunctionSelector = bytes4(keccak256("ownerOf(uint256)"));
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public constant SALES_ROLE = keccak256("SALES_ROLE");
    bytes32 public constant RESERVED_MINT_ROLE = keccak256("RESERVED_MINT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MERKLE_ROLE = keccak256("MERKLE_ROLE");

    uint256[] public saleIsActive;

    struct saleSchedule {
        uint256 start;
        uint256 end;
    }

    struct foreignTokenLimitsRule {
        address foreignContract;
        uint256 foreignTokenTypeId;
        uint256 multiplier;
        saleSchedule schedule;
    }

    foreignTokenLimitsRule[] public foreignTokenLimits;
    mapping(uint256 => saleSchedule) public saleSchedules;
    bool public saleMaxLock = false;
    bool public allowContractMints = false;
    bool public allowNonRandomMinting = true;
    bool[] public discountUsed;

    Counters.Counter public reservedSupply;

    string private _contractURI = "https://www.7art.io/bibi-beck/pop-genesis-collection/metadata_contract.json";  //The URI to the contract json

    constructor(string memory uri_, address[] memory _payees, uint256[] memory _shares) ERC1155(uri_) PaymentSplitter(_payees, _shares) payable {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(URI_SETTER_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(SALES_ROLE, msg.sender);
        _setupRole(RESERVED_MINT_ROLE, msg.sender);
        _setupRole(MERKLE_ROLE, msg.sender);
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

     /**
     * @dev Sets the value of `allowNonRandomMinting`.
     *
     * Requirements:
     *
    * - the caller must have the `SALES_ROLE`.
      *
     * @param _allowNonRandomMinting The new value for `allowNonRandomMinting`.
     */

    function setAllowNonRandomMinting(bool _allowNonRandomMinting) public onlyRole(SALES_ROLE) {
        allowNonRandomMinting = _allowNonRandomMinting;
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Retrieves the summary of mint counts for a given wallet.
     * @param wallet The address of the wallet.
     * @return The total sum of mint counts for the wallet.
     */
     function getMintCountSummary(address wallet) public view returns (uint256) {
        uint256 summary = 0;

        for (uint256 i = 0; i < saleIsActive.length; i++) {
            summary += mintCount[wallet][saleIsActive[i]];
        }

        return summary;
    }

    /**
    * @dev Increments the mint count for the specified wallet, token IDs, and amounts.
    *
    * @param to The address of the wallet.
    * @param ids The array of token IDs.
    * @param amounts The array of corresponding token amounts.
    */
    function incrementMintCount(address to, uint256[] memory ids, uint256[] memory amounts) internal {
        uint256 idsLen = ids.length;
        for (uint256 i = 0; i < idsLen; ++i) {
            mintCount[to][ids[i]] += amounts[i];
        }
    }

    /**
     * @dev Finds the token IDs with the least minted count for a given wallet address.
     *
     * This function returns an array of token IDs that have the least minted count for the specified wallet.
     * If multiple token IDs have the same least minted count, all of them will be included in the result.
     *
     * Requirements:
     * - `wallet` must be a valid address.
     *
     * @param wallet The wallet address for which to find the least owned token IDs.
     * @return An array of token IDs with the least minted count for the specified wallet.
     */

    function findLeastOwnedIds(address wallet) public view returns (uint256[] memory) {
        uint256[] memory leastOwnedIds;
        uint256 leastBalance = mintCount[wallet][saleIsActive[0]];
        uint256 leastOwnedCount = 0;

        for (uint256 i = 0; i < saleIsActive.length; i++) {
            uint256 tokenId = saleIsActive[i];
            uint256 balance = mintCount[wallet][tokenId];

            if (balance < leastBalance) {
                leastBalance = balance;
                leastOwnedCount = 1;
            } else if (balance == leastBalance) {
                leastOwnedCount++;
            }
        }

        leastOwnedIds = new uint256[](leastOwnedCount);
        uint256 index = 0;

        for (uint256 i = 0; i < saleIsActive.length; i++) {
            uint256 tokenId = saleIsActive[i];
            if (mintCount[wallet][tokenId] == leastBalance) {
                leastOwnedIds[index] = tokenId;
                index++;
            }
        }
        return leastOwnedIds;
    }

    function createArrayWithSameNumber(uint256 amount, uint256 number) internal pure returns (uint256[] memory) {
        uint256[] memory newArray = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            newArray[i] = number;
        }
        return newArray;
    }

    function shuffleArray(uint256[] memory array, uint256 seed) internal view returns (uint256[] memory) {
        uint256[] memory shuffled = array;
        uint256 length = shuffled.length;

        for (uint256 i = length; i > 0; i--) {
            uint256 j = _getRandomIndex(i, seed);
            uint256 temp = shuffled[i - 1];
            shuffled[i - 1] = shuffled[j];
            shuffled[j] = temp;
            seed++;
        }

        return shuffled;
    }

    function mint(address to, uint256 id, uint256 amount, uint256 discountTokenId, bytes32[] calldata proof, bytes memory data)
    public
    payable
    {
        require(msg.sender == tx.origin || allowContractMints, "No contracts!");
        require(checkSaleState(id), "Sale not active");
        require(_checkSaleSchedule(saleSchedules[id]), "Not at this time");
        require(tokenMaxSupply[id] == 0 || totalSupply(id) + amount <= tokenMaxSupply[id], "Supply exhausted");
        require(perWalletMaxTokens[id] == 0 || balanceOf(to,id) + amount <= perWalletMaxTokens[id], "Reached per-wallet limit!");
        require(checkForeignTokenLimits(to, amount), "Not enough foreign tokens");
        require((merkleRoot == 0 || _verify(_leaf(msg.sender), proof) || _verify(_leaf(to), proof)), "Invalid Merkle proof");
        require(discountTokenId <= discountUsed.length, "discountTokenId is out of range");
        require(_checkPrice(amount, discountTokenId), "Not enough ETH");

        if (id == 0) {
            uint256[] memory leastOwnedIds = findLeastOwnedIds(to);
            // Shuffle the leastOwnedIds array
            require(leastOwnedIds.length >= amount, "Unreasonable randomization request");
            uint256 nounce = amount;
            leastOwnedIds = shuffleArray(leastOwnedIds, nounce);

            uint256[] memory randomIds = new uint256[](amount);
            uint256 uniqueCount = 0;

            for (uint256 i = 0; i < amount; i++) {
                randomIds[i] = leastOwnedIds[i];
                uniqueCount++;
            }

            require(uniqueCount == amount, "Unable to generate unique token IDs");
            uint256[] memory amounts = createArrayWithSameNumber(amount, 1);
            incrementMintCount(to, randomIds, amounts);
            _mintBatch(to, randomIds, amounts, data);
            return;
        } else {
            require(allowNonRandomMinting, "Only random minting");
            mintCount[to][id] += amount;
            _mint(to, id, amount, data);
        }
    }

    function _getRandomIndex(uint256 length, uint256 nonce) internal view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    block.number,
                    blockhash(block.number - 1),
                    msg.sender,
                    nonce
                )
            )
        );
        return seed % length;
    }
    function calculateForeignTokenCountMultiplied(address _wallet) public view returns (uint256) {
        uint256 foreignTokenCountMultiplied = 0;
        for (uint256 i = 0; i < foreignTokenLimits.length; i++) {
            if (_checkSaleSchedule(foreignTokenLimits[i].schedule)) {
                // add foreignToken Balance * multiplier
                foreignTokenCountMultiplied += _walletHoldsForeign1155TokenCount(_wallet, foreignTokenLimits[i].foreignTokenTypeId, foreignTokenLimits[i].foreignContract) * foreignTokenLimits[i].multiplier;
            }
        }
        return foreignTokenCountMultiplied;
    }

    function checkForeignTokenLimits(address _wallet, uint256 _desiredAmount) public view returns (bool) {
        // If there are no rules, it is always okay to mint
        if (foreignTokenLimits.length < 1) {
            return true;
        }

        // Use the new function here
        uint256 foreignTokenCountMultiplied = calculateForeignTokenCountMultiplied(_wallet);

        // If the sum of mintCounts + desiredAmount is less than or equal to the foreignTokenCountMultiplied
        if (getMintCountSummary(_wallet) + _desiredAmount <= foreignTokenCountMultiplied)  {
            return true;
        }

        return false;
    }

    function checkSaleState(uint256 _id) internal view returns (bool){
        if (_id == 0 && saleIsActive.length > 0) {
            // allow random (0) if anything is on sale
            return true;
        }
        for (uint256 i=0; i<saleIsActive.length; i++) {
            if (saleIsActive[i] == _id) {
                return true;
            }
        }
        return false;
    }

    function setSaleActive(uint256[] memory ids, uint256[] memory tokenMaxSupplys, bool _globalLockAfterUpdate) external onlyRole(SALES_ROLE){
        require(ids.length == tokenMaxSupplys.length, "Array lengths must match");
        saleIsActive = ids;
        if (!saleMaxLock) {
            for (uint256 i = 0; i < ids.length; i++) {
                uint256 tokenId = ids[i];
                uint256 limit = tokenMaxSupplys[i];
                tokenMaxSupply[tokenId] = limit;
            }
            saleMaxLock = _globalLockAfterUpdate;
        }
    }

    function addForeignTokenLimitRule(
        address _foreignContract,
        uint256 _foreignTokenTypeId,
        uint256 _multiplier,
        uint256 _start,
        uint256 _end
    ) external onlyRole(SALES_ROLE) {
        saleSchedule memory schedule = saleSchedule(_start, _end);
        foreignTokenLimits.push(
            foreignTokenLimitsRule(
                _foreignContract,
                _foreignTokenTypeId,
                _multiplier,
                schedule
            )
        );
    }

    function resetForeignTokenLimits() external onlyRole(SALES_ROLE) {
        delete foreignTokenLimits;
    }

    function setSaleSchedule(uint256 _id, uint256 _start, uint256 _end) external onlyRole(SALES_ROLE){
        require(_id > 0, "Invalid token type ID");
        saleSchedules[_id].start = _start;
        saleSchedules[_id].end = _end;
    }


    function flipAllowContractMintsState() external onlyRole(ADMIN_ROLE){
        allowContractMints = !allowContractMints;
    }

    function mintReservedTokens(address to, uint256 id, uint256 amount, bytes memory data) external onlyRole(RESERVED_MINT_ROLE){
        require(id > 0, "Invalid token type ID");
        require(reservedSupply.current() + amount <= NUMBER_RESERVED_TOKENS, "amount over max allowed");
        require(amount == 1 || hasRole(ADMIN_ROLE, _msgSender()), "> 1 only ADMIN_ROLE");
        _mint(to, id, amount, data);
        for (uint i = 0; i < amount; i++)
        {
            reservedSupply.increment();
        }
    }

    function withdraw() external onlyRole(WITHDRAW_ROLE){
        payable(msg.sender).transfer(address(this).balance);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes32[] calldata proof, bytes memory data)
    public
    payable
    {
        require(allowNonRandomMinting, "Only random minting");
        require(msg.sender == tx.origin || allowContractMints, "No contracts!");
        require((merkleRoot == 0 || _verify(_leaf(msg.sender), proof) || _verify(_leaf(to), proof)), "Invalid Merkle proof");
        uint256 idsLen = ids.length;
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < idsLen; ++i) {
            require(ids[i] > 0, "Invalid token type ID");
            require(checkSaleState(ids[i]), "Sale not active");
            require(_checkSaleSchedule(saleSchedules[ids[i]]), "Not at this time");
            require(tokenMaxSupply[ids[i]] == 0 || totalSupply(ids[i]) + amounts[i] <= tokenMaxSupply[ids[i]], "Supply exhausted");
            require(perWalletMaxTokens[ids[i]] == 0 || balanceOf(to, ids[i]) + amounts[i] <= perWalletMaxTokens[ids[i]], "Reached per-wallet limit!");
            totalAmount = totalAmount + amounts[i];
        }
        require(checkForeignTokenLimits(to, totalAmount), "Not enough foreign tokens");
        require(_checkPrice(totalAmount, 0), "Not enough ETH");

        incrementMintCount(to,ids,amounts);
        _mintBatch(to, ids, amounts, data);
    }


    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    whenNotPaused
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(MERKLE_ROLE){
        merkleRoot = _merkleRoot;
    }

    function setSaleMax(uint32 _limit, uint256 _id, bool _globalLockAfterUpdate) external onlyRole(SALES_ROLE){
        require(saleMaxLock == false , "saleMaxLock is set");
        require(_id > 0, "Invalid token type ID");
        saleMaxLock = _globalLockAfterUpdate;
        tokenMaxSupply[_id] = _limit;
    }

    function setPrice(uint256 _price) external onlyRole(SALES_ROLE){
        price = _price;
    }

    function setWalletMax(uint256 _id, uint256 _walletLimit) external onlyRole(SALES_ROLE){
        require(_id > 0, "Invalid token type ID");
        perWalletMaxTokens[_id] = _walletLimit;
    }

    function setDiscountOwnerFunctionSelector(bytes4 _discountOwnerFunctionSelector) external onlyRole(SALES_ROLE){
        discountOwnerFunctionSelector = _discountOwnerFunctionSelector;
    }

    function setContractURI(string memory _uri) external onlyRole(ADMIN_ROLE) {
        _contractURI = _uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function _checkSaleSchedule(saleSchedule memory s)
    internal view returns (bool)
    {
        if (
            (s.start == 0 || s.start <= block.timestamp)
            &&
            (s.end == 0 ||s.end >= block.timestamp)
        )
        {
            return true;
        }
        return false;
    }


    function _checkPrice(uint256 amount, uint256 discountTokenId)
    internal returns (bool)
    {
        if (msg.value >= price * amount) {
            return true;
        } else if (discountTokenId > 0 && discountTokenId <= discountUsed.length && amount == 1 && _walletHoldsUnusedDiscountToken(msg.sender, discountContract, discountTokenId)) {
            uint256 discountedPrice = price - discount; // discount in wei
            if (msg.value >= discountedPrice) {
                discountUsed[discountTokenId - 1] = true;
                return true;
            }
        }
        return false;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 32))
        }
    }

    function _walletHoldsUnusedDiscountToken(address _wallet, address _contract, uint256 discountTokenId) internal returns (bool) {
        if ((discountTokenId <= discountUsed.length || discountUsed[discountTokenId - 1] == false)) {
            (bool success, bytes memory owner) = _contract.call(abi.encodeWithSelector(discountOwnerFunctionSelector, discountTokenId));
            require (success, "ownerOf call failed");
            require (bytesToAddress(owner) == _wallet, "Owner of discountToken not equal mint sender");
            return true;
        }
        require (false, "TokenId invalid or used");
        return false;
    }

    function _walletHoldsForeign1155TokenCount(address _wallet, uint256 _foreignTokenId, address _contract) internal view returns (uint256) {
        ERC1155 token = ERC1155(_contract);
        return token.balanceOf(_wallet, _foreignTokenId);
    }

    function setDiscountContract(address _discountContract, uint256 _maxTokenId, uint256 _discount) external onlyRole(ADMIN_ROLE) {
        if (discountContract != _discountContract) {
            // reset all tokenId states to false
            discountUsed = new bool[](_maxTokenId);
        }
        discountContract = _discountContract;
        discount = _discount;
    }
}