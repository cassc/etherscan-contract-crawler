// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

//         ,~~~~~~,
//        /   *   |\_________________
//       [   * *  |_________ ~ _ ~ __)
//        \ * * * |/        | | | |
//         '~~~~~~'         "-" |_|

contract DawnKey is ERC1155, Ownable {
    bool public active;
    address public signerAddress;
    uint256 public dkTokenId = 321;
    mapping(address => uint8) public nClaimed;
    mapping(string => address) public dawnTrilogy;
    using ECDSA for bytes32;

    Counters.Counter public dkCounter;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    constructor(
        string memory uriBase,
        string memory _name,
        string memory _symbol,
        address efAddress,
        address vAddress,
        address cAddress,
        address _signerAddress
    ) ERC1155(uriBase) {
        name = _name;
        symbol = _symbol;
        signerAddress = _signerAddress;
        dawnTrilogy["eternalFragments"] = efAddress;
        dawnTrilogy["vortex"] = vAddress;
        dawnTrilogy["chromospheres"] = cAddress;
    }

    /** @dev Claim a Dawn Key
     * @param quantity The quantity to claim
     * @param maxKeys The maximum number of keys allocated to this address in the snapshot
     * @param signature A signature to authenticate the claim
     */
    function claim(
        uint8 quantity,
        uint16 maxKeys,
        bytes memory signature
    ) public {
        /// require an active contract
        require(active, "Contract is not active");

        /// verify the signature
        require(checkSignature(signature, maxKeys), "Invalid signature");

        /// check that the current balance indicates that the key is not claimed
        /// to prevent calling claim and spending gas when it will have no effect
        require(
            quantity + nClaimed[msg.sender] <= maxKeys,
            "Quantity requested is too high"
        );

        /// mint
        _mint(msg.sender, dkTokenId, quantity, "");

        nClaimed[msg.sender] += quantity;

        dkCounter._value += quantity;
    }

    /** @dev verify a signature */
    function checkSignature(bytes memory signature, uint16 maxKeys)
        public
        view
        returns (bool)
    {
        bytes32 messageHash = keccak256(abi.encode(this, msg.sender, maxKeys));
        return
            signerAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    /** @dev set address of the signer */
    function setSignerAddress(address _signerAddress) public onlyOwner {
        signerAddress = _signerAddress;
    }

    /** @dev Return the maximum number of active keys a wallet could have based on Dawn Trilogy balances
    @param tokenHolder a wallet address
     */
    function getMaxNumActiveDawnKeys(address tokenHolder)
        public
        view
        returns (uint256)
    {
        /// get the balance for each Dawn Trilogy collection
        /// and the maximum number of DKs according to the tokenHolder's balance
        uint256 eternalFragmentsBalance = ERC721Enumerable(
            dawnTrilogy["eternalFragments"]
        ).balanceOf(tokenHolder);

        /// require 3 eternal fragments per active dawn key
        uint256 eternalFragmentsLimit = eternalFragmentsBalance / 3;

        uint256 vortexBalance = ERC721Enumerable(dawnTrilogy["vortex"])
            .balanceOf(tokenHolder);

        /// require 2 vortexes per active dawn key
        uint256 vortexLimit = vortexBalance / 2;

        uint256 chromospheresBalance = ERC721Enumerable(
            dawnTrilogy["chromospheres"]
        ).balanceOf(tokenHolder);

        /// require 1 chromosphere per active dawn key
        uint256 chromospheresLimit = chromospheresBalance;

        /// calculate the maximum possible number of active keys
        /// based on dawn trilogy balances
        /// maxNumActiveKeys = min(efLimit, vLimit, cLimit)

        uint256 maxNumActiveKeys = eternalFragmentsLimit < vortexLimit
            ? eternalFragmentsLimit
            : vortexLimit;

        maxNumActiveKeys = maxNumActiveKeys < chromospheresLimit
            ? maxNumActiveKeys
            : chromospheresLimit;

        return maxNumActiveKeys;
    }

    /** @dev Return the maximum number of active keys a wallet could have based on Dawn Trilogy balances
    @param tokenHolder a wallet address
     */
    function getNumActiveDawnKeys(address tokenHolder)
        public
        view
        returns (uint256)
    {
        /// get the max num of active dawn keys tokenHolder can have
        uint256 maxNumActiveDawnKeys = getMaxNumActiveDawnKeys(tokenHolder);
        /// get the tokenHolder's current dawn key balance
        uint256 balance = balanceOf(tokenHolder, dkTokenId);
        /// calculate the number of active dawn keys
        return maxNumActiveDawnKeys < balance ? maxNumActiveDawnKeys : balance;
    }

    /** @dev set a new URI */
    function setURI(string memory _uri) public onlyOwner {
        _setURI(_uri);
    }

    /** @dev toggle active boolean */
    function toggleActive() public onlyOwner {
        active = !active;
    }

    /** @dev A backup function for the team to generate a DawnKey */
    function ownerClaim() public onlyOwner {
        _mint(msg.sender, dkTokenId, 1, "");
    }

    /**
     * @notice Override ERC1155 such that zero amount token transfers are disallowed to prevent arbitrary creation of new tokens in the collection.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(amount > 0, "AMOUNT_CANNOT_BE_ZERO");
        return super.safeTransferFrom(from, to, id, amount, data);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "BALANCE_IS_ZERO");
        payable(msg.sender).transfer(address(this).balance);
    }
}