// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
    ERC1155 Smart Contract - Finding Tschitsch by Daniel Tschitsch

 _______ _________ _        ______  _________ _        _______   _________ _______  _______          __________________ _______  _______
(  ____ \\__   __/( (    /|(  __  \ \__   __/( (    /|(  ____ \  \__   __/(  ____ \(  ____ \|\     /|\__   __/\__   __/(  ____ \(  ____ \|\     /|
| (    \/   ) (   |  \  ( || (  \  )   ) (   |  \  ( || (    \/     ) (   | (    \/| (    \/| )   ( |   ) (      ) (   | (    \/| (    \/| )   ( |
| (__       | |   |   \ | || |   ) |   | |   |   \ | || |           | |   | (_____ | |      | (___) |   | |      | |   | (_____ | |      | (___) |
|  __)      | |   | (\ \) || |   | |   | |   | (\ \) || | ____      | |   (_____  )| |      |  ___  |   | |      | |   (_____  )| |      |  ___  |
| (         | |   | | \   || |   ) |   | |   | | \   || | \_  )     | |         ) || |      | (   ) |   | |      | |         ) || |      | (   ) |
| )      ___) (___| )  \  || (__/  )___) (___| )  \  || (___) |     | |   /\____) || (____/\| )   ( |___) (___   | |   /\____) || (____/\| )   ( |
|/       \_______/|/    )_)(______/ \_______/|/    )_)(_______)     )_(   \_______)(_______/|/     \|\_______/   )_(   \_______)(_______/|/     \|

  _           ___            _     _   _____       _    _ _          _
 | |__ _  _  |   \ __ _ _ _ (_)___| | |_   _|__ __| |_ (_) |_ ___ __| |_
 | '_ \ || | | |) / _` | ' \| / -_) |   | |(_-</ _| ' \| |  _(_-</ _| ' \
 |_.__/\_, | |___/\__,_|_||_|_\___|_|   |_|/__/\__|_||_|_|\__/__/\__|_||_|
       |__/
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
contract Finding_Tschitsch_by_Daniel_Tschitsch is ERC1155, AccessControl, ERC1155Burnable,Pausable, ERC1155Supply, PaymentSplitter {

    using Counters for Counters.Counter;

    uint public constant NUMBER_RESERVED_TOKENS = 500;
    uint256 public price = 1e18; // The initial price to mint in WEI.
    uint256 public discount = 0;

    mapping(uint256 => uint256) public tokenMaxSupply; // 0 is openEnd
    mapping(uint256 => uint256) public perWalletMaxTokens; // 0 is openEnd

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

    mapping(uint256 => bool) public saleIsActive;

    struct saleSchedule {
        uint256 start;
        uint256 end;
    }
    mapping(uint256 => saleSchedule) public saleSchedules;
    bool public saleMaxLock = false;
    bool public allowContractMints = false;
    bool[] public discountUsed;

    Counters.Counter public reservedSupply;

    string private _contractURI;  //The URI to the contract json

    constructor(string memory uri_, address[] memory _payees, uint256[] memory _shares) ERC1155(uri_) PaymentSplitter(_payees, _shares) payable {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(URI_SETTER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(WITHDRAW_ROLE, msg.sender);
        _setupRole(SALES_ROLE, msg.sender);
        _setupRole(RESERVED_MINT_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MERKLE_ROLE, msg.sender);
        _setupRole(RESERVED_MINT_ROLE, msg.sender);
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

    function mint(address to, uint256 id, uint256 amount, uint256 discountTokenId, bytes32[] calldata proof, bytes memory data)
    public
    payable
    {
        require(id > 0, "Invalid token type ID");
        require(msg.sender == tx.origin || allowContractMints, "No contracts!");
        require(saleIsActive[id], "Sale not active");
        require(_checkSaleSchedule(id), "Not at this time");
        require(tokenMaxSupply[id] == 0 || totalSupply(id) + amount <= tokenMaxSupply[id], "Supply exhausted");
        require(perWalletMaxTokens[id] == 0 || balanceOf(to,id) + amount <= perWalletMaxTokens[id], "Reached per-wallet limit!");
        require((merkleRoot == 0 || _verify(_leaf(msg.sender), proof)|| _verify(_leaf(to), proof)), "Invalid Merkle proof");
        require(discountTokenId <= discountUsed.length, "discountTokenId is out of range");
        require(_checkPrice(amount, discountTokenId), "Not enough ETH");
        _mint(to, id, amount, data);
    }

    function flipSaleState(uint256 _id) external onlyRole(SALES_ROLE){
        require(_id > 0, "Invalid token type ID");
        saleIsActive[_id] = !saleIsActive[_id];
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
        require(msg.sender == tx.origin || allowContractMints, "No contracts!");
        require((merkleRoot == 0 || _verify(_leaf(msg.sender), proof)|| _verify(_leaf(to), proof)), "Invalid Merkle proof");
        uint256 idsLen = ids.length;
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < idsLen; ++i) {
            require(ids[i] > 0, "Invalid token type ID");
            require(saleIsActive[ids[i]], "Sale not active");
            require(_checkSaleSchedule(ids[i]), "Not at this time");
            require(tokenMaxSupply[ids[i]] == 0 || totalSupply(ids[i]) + amounts[i] <= tokenMaxSupply[ids[i]], "Supply exhausted");
            require(perWalletMaxTokens[ids[i]] == 0 || balanceOf(to,ids[i]) + amounts[i] <= perWalletMaxTokens[ids[i]], "Reached per-wallet limit!");
            totalAmount = totalAmount + amounts[i];
        }
        require(_checkPrice(totalAmount,0), "Not enough ETH");
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

    function _checkSaleSchedule(uint256 _id)
    internal view returns (bool)
    {
        if (
            (saleSchedules[_id].start == 0 || saleSchedules[_id].start <= block.timestamp)
            &&
            (saleSchedules[_id].end == 0 || saleSchedules[_id].end >= block.timestamp)
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

    function setDiscountContract(address _discountContract, uint256 _maxTokenId, uint256 _discount) external onlyRole(ADMIN_ROLE) {
        if (discountContract != _discountContract) {
            // reset all tokenId states to false
            discountUsed = new bool[](_maxTokenId);
        }
        discountContract = _discountContract;
        discount = _discount;
    }
}