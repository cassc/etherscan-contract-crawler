// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./YatSignatures.sol";

contract YatGems is ERC1155, Ownable, YatSignatures {
    using SafeCast for uint256;
    using Strings for uint256;

    // For each Gem (series) we have a name, and the counter of the gems that have been minted in that series.
    struct GemInfo {
        string uuid;
        string name;
        uint256 supplyCap;
        uint256 supply;
    }

    //----------------------------------------    Modifiers and Events    ----------------------------------------------

    modifier onlyAdmin {
        require(isAdmin(_msgSender()), "Not an Admin");
        _;
    }

    modifier onExistingGem(uint256 gemId) {
        require(gemExists(gemId), "Gem must exist");
        _;
    }

    event TokenMinted(uint256 gemId, string fragmentId, address to);
    event NewGemCreated(uint256 gemId, string gemUuid, string name, uint256 supplyCap);
    event ContractURISet(string contractUri);
    event AdminAdded(address admin);
    event AdminRemoved(address admin);

    //---------------------------------------      State variables       -----------------------------------------------
    string public contractURI;
    string  public name;
    mapping(uint256 => GemInfo) private _gemInfo; // A mapping of the Gem (series) id and its metadata
    mapping(address => bool) private _admins;
    mapping(string => bool) private _usedSignatures;
    mapping(uint256 => mapping(address => uint256)) private _burns;
    //-----------------------------------------      Constructor       -------------------------------------------------

    constructor(
        address[] memory admins_,
        string memory name_,
        string memory tokenBaseURI_,
        string memory contractURI_,
        address authorizedSigner
    )
    ERC1155(tokenBaseURI_)
    YatSignatures(authorizedSigner)
    {
        addAdmin(msg.sender);
        for (uint256 i = 0; i < admins_.length; i++) {
            addAdmin(admins_[i]);
        }
        name = name_;
        contractURI = contractURI_;
    }

    //-------------------------------------------    Signature override  -----------------------------------------------
    function _signaturePrefix() internal pure override returns (string memory) {
        return "YatGems";
    }

    /**
    * Override the challenge calculation to disable the use of nonces
    */
    function _calculateChallenge(string memory message, address account, uint256 expiry) internal virtual override returns (bytes32) {
        string memory prefix = _signaturePrefix();
        bytes32 hash = keccak256(abi.encodePacked(prefix, message, account, expiry));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    //-------------------------------------------    Gem functions       -----------------------------------------------

    function mintNewGem(string memory name, string memory gemUuid, uint256 gemSupplyCap) public onlyAdmin {
        require(bytes(name).length > 0, "Gem name cannot be empty");
        uint256 gemId = uuidToUint(gemUuid);
        require(!gemExists(gemId), "Gem already exists");
        GemInfo memory info = GemInfo(gemUuid, name, gemSupplyCap, 0);
        _gemInfo[gemId] = info;
        emit NewGemCreated(gemId, gemUuid, name, gemSupplyCap);
    }

    /**
    * Returns the name of the gem at index `gemId`, or an empty string if it does not exist
    */
    function gemName(uint256 gemId) public view returns (string memory) {
        return _gemInfo[gemId].name;
    }

    /**
    * Returns the supply cap the gem at index `gemId`, or 0 if it does not exist
    */
    function supplyCap(uint256 gemId) public view returns (uint256) {
        return _gemInfo[gemId].supplyCap;
    }

    /**
    * Returns the supply cap the gem at index `gemId`, or 0 if it does not exist
    */
    function currentSupply(uint256 gemId) public view returns (uint256) {
        return _gemInfo[gemId].supply;
    }

    /**
    * Returns true if this Gem has been created or not.
    * Because `name` cannot be empty, we use this as the existence test
    */
    function gemExists(uint256 gemId) public view returns (bool) {
        return bytes(_gemInfo[gemId].name).length > 0;
    }

    function uuidToUint(string memory uuid) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(uuid)));
    }

    //-------------------------------------------    Gem token functions    --------------------------------------------

    /**
    * Override  _beforeTokenTransfer to ensure that
    * - When minting, the token doesn't already exist, and the gem DOES exist, and we don't hit supply cap
    * - When burning, no extra checks are made
    * - When transferring, no extra checks are made
    */
    function _beforeTokenTransfer(
        address _operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory _data
    ) internal view override {
        // No need to check array lengths are equal. This is done already in the calling function.
        // balance checks are done after this call in main super.transfer function

        // Checks for all types of transfers
        for (uint256 i = 0; i < ids.length; i++) {
            require(gemExists(ids[i]), "Gem must exist");
            require(amounts[i] > 0, "Cannot transfer 0 fragments");
        }

        if (from == address(0) && to != address(0)) {// we are MINTING
            for (uint256 i = 0; i < ids.length; i++) {
                // Check that the gems exist
                uint256 gemId = ids[i];
                uint256 amount = amounts[i];
                // Check that we're not exceeding the supply cap with this mint
                GemInfo storage info = _gemInfo[gemId];
                require(info.supply + amount <= info.supplyCap, "Mint would exceed gem max supply");
            }
        }
    }

    function _afterTokenTransfer(address from, address to, uint256 gemId, uint256 amount) internal {
        if (from == address(0) && to != address(0)) {// we are MINTING
            GemInfo storage info = _gemInfo[gemId];
            info.supply += amount;
        }
        // For burning:
        // Do nothing. The spec says that we track the total supply ever minted, so this never goes down
        // For transfers, the supply does not change, so still do nothing.
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            _afterTokenTransfer(from, to, ids[i], amounts[i]);
        }
    }

    /**
    * An admin can mint a token on behalf of a user. It will assign the next token index for the existing gemId (which
    * must exist, and transfer ownership to the user
    */
    function adminMint(address to, uint256 gemId, string memory uuid) public onlyAdmin onExistingGem(gemId) {
        string memory fragmentId = _fragmentId(gemId, uuid);
        _mintToken(to, gemId, fragmentId);
    }

    function _fragmentId(uint256 gemId, string memory uuid) internal pure returns (string memory) {
        return string(abi.encodePacked(gemId.toHexString(), "|", uuid));
    }

    function mint(uint256 gemId, string memory uuid, uint256 expiry, bytes memory signature) public onExistingGem(gemId) {
        string memory fragmentId = _fragmentId(gemId, uuid);
        address to = msg.sender;
        require(!_usedSignatures[fragmentId], "Signature has already been used");
        bool isValidSig = _verifySignature(fragmentId, to, expiry, signature);
        require(isValidSig, "Invalid minting signature");
        _mintToken(to, gemId, fragmentId);
    }

    // Invalidate the signature, then call mint, then emit
    function _mintToken(address to, uint256 gemId, string memory fragmentId) private {
        require(_usedSignatures[fragmentId] == false, "Fragment has already been minted");
        _usedSignatures[fragmentId] = true;
        _mint(to, gemId, 1, "");
        _afterTokenTransfer(address(0), to, gemId, 1);
        emit TokenMinted(gemId, fragmentId, to);
    }

    // Burns fragments. Only the token owner can burn. As part of the burn, we record that the user has burnt this fragment
    // so that they may be able to mint an effigy gem fragment in future
    function burn(uint256 gemId, uint256 amount) public {
        ERC1155._burn(msg.sender, gemId, amount);
        _burns[gemId][msg.sender] += amount;
    }

    // Returns the number of gem fragments that the given address has burnt
    function burnCount(address from, uint256 gemId) public view returns (uint256) {
        return _burns[gemId][from];
    }

    //---------------------------- Transfer and Ownership functions ---------------------------//

    function addAdmin(address newAdmin) public onlyOwner {
        _admins[newAdmin] = true;
        emit AdminAdded(newAdmin);
    }

    function revokeAdmin(address admin) public onlyOwner {
        require(admin != owner(), "Can't remove owner from admins");
        _admins[admin] = false;
        emit AdminRemoved(admin);
    }

    function isAdmin(address addr) public view returns (bool) {
        return _admins[addr];
    }

    function transfer(string memory gemUuid, uint256 amount, address to) public {
        uint256 gemId = uuidToUint(gemUuid);
        safeTransferFrom(msg.sender, to, gemId, amount, "");
    }

    //---------------------------- Metadata / OpenSea functions ---------------------------//

    function setContractURI(string memory newContractURI) public onlyAdmin {
        contractURI = newContractURI;
        emit ContractURISet(contractURI);
    }

    function setURI(string memory newURI) public onlyAdmin {
        _setURI(newURI);
    }

    //---------------------------- interface support ---------------------------//

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}