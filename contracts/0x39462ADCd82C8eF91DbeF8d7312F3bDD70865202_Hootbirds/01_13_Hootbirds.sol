// SPDX-License-Identifier: MIT
/*
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
+                                                                                                                 +
+                                                                                                                 +
.                        .^!!~:                                                 .^!!^.                            .
.                            :7Y5Y7^.                                       .^!J5Y7^.                             .
.                              :!5B#GY7^.                             .^!JP##P7:                                  .
.   7777??!         ~????7.        :[email protected]@@@&GY7^.                    .^!JG#@@@@G^        7????????????^ ~????77     .
.   @@@@@G          [email protected]@@@@:       J#@@@@@@@@@@&G57~.          .^7YG#@@@@@@@@@@&5:      #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:     :[email protected]@@@@[email protected]@@@@@@@@&B5?~:^7YG#@@@@@@@@[email protected]@@ @@&!!     #@@@@@@@@@@@@@? [email protected]@@@@@    .
.   @@@@@G          [email protected]@@@@:    [email protected]@@@#[email protected]@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@P   ^[email protected]@@@@~.   ^~~~~~^[email protected] @@@@??:~~~~~    .
.   @@@@@B^^^^^^^^. [email protected]@@@@:   [email protected]@@@&^   [email protected][email protected]@@@@@&@@@@@@@@@@@&@J7&@@@@@#.   [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@B   ^B&&@@@@@#!#@@@@@@@@@@7G&&@@@@@#!     [email protected]@@@#.           [email protected]@@@@?            .
.   @@@@@@@@@@@@@@! [email protected]@@@@:   [email protected]@@@&^    !YPGPY!  [email protected]@@@@Y&@@@@Y  ~YPGP57.    [email protected]@@@P           [email protected]@@@@?            .
.   @@@@@B~~~~~~~!!.?GPPGP:   [email protected]@@@&7           ?&@@@@P [email protected]@@@@5.          [email protected]@@@&^            [email protected]@@@@?            .
.   @@@@@G          ^~~~~~.    :[email protected]@@@@BY7~^^~75#@@@@@5.    [email protected]@@@@&P?~^^^[email protected]@@@@#~             [email protected]@@@@?            .
.   @@@@@G          [email protected]@@@@:      [email protected]@@@@@@@@@@@@@@@B!!      ^[email protected]@@@@@@@@@@@@@@@&Y               [email protected]@@@@?            .
.   @@@@@G.         [email protected]@@@@:        !YB&@@@@@@@@&BY~           ^JG#@@@@@@@@&#P7.                [email protected]@@@@?            .
.   YYYYY7          !YJJJJ.            :~!7??7!^:                 .^!7??7!~:                   ^YJJJY~            .
.                                                                                                                 .
.                                                                                                                 .
.                                                                                                                 .
.                                  ………………               …………………………………………                  …………………………………………        .
.   PBGGB??                      7&######&5            :B##############&5               .G#################^      .
.   &@@@@5                      [email protected]@@@@@@@@@           :@@@@@@@@@@@@@@@@@G               &@@@@@@@@@@@@ @@@@@^      .
.   PBBBBJ                 !!!!!JPPPPPPPPPY !!!!!     :&@@@@P?JJJJJJJJJJJJJJ?      :JJJJJJJJJJJJJJJJJJJJJJ.       .
.   ~~~~~:                .#@@@@Y          [email protected]@@@@~    :&@@@@7           [email protected]@@&.      ^@@@@.                        .
.   #@@@@Y                .#@@@@[email protected]@@@@~    :&@@@@7   !JJJJJJJJJJJJ?     :JJJJJJJJJJJJJJJJJ!!           .
.   #@@@@Y                .#@@@@@@@@@@@@@@@@@@@@@@~   :&@@@@7   [email protected]@@@@@@@G &@@             @@@@@@@@@@P            .
.   #@@@@Y                .#@@@@&##########&@@@@@~    :&@@@@7   7YYYYYYYYJ???7             JYYYYYYYYYYYYJ???7     .
.   #@@@@Y                .#@@@@5 ........ [email protected]@@@@~    :&@@@@7            [email protected]@@&.                         [email protected]@@#     .
.   #@@@@#5PPPPPPPPPJJ    .#@@@@Y          [email protected]@@@@~    :&@@@@P7??????????JYY5J      .?????????? ???????JYY5J       .
.   &@@@@@@@@@@@@@@@@@    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@@@P            .
.   PBBBBBBBBBBBBBBBBY    .#@@@@Y          [email protected]@@@@~    :&@@@@@@@@@@@@@@@@@G         ^@@@@@@@@@@@@@@@ @@5           .
+                                                                                                                 +
+                                                                                                                 +
+ + + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - + + +
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title Crypto
 * @author HootLabs
 */
contract Crypto {
    bytes constant ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    /**
     * @notice base58 is used to calculate the base58 encoded value of given bytes.
     * This algorithm was migrated from github.com/mr-tron/base58 to solidity by our developers.
     * Note that it is not yet optimized for gas, so please use it only in read-only scenarios.
     * @param data_ bytes.
     * @return base58 encoded results.
     */
    function base58(bytes memory data_) public pure returns (bytes memory){
        uint256 size = data_.length;
        uint256 zeroCount;
        while (zeroCount < size && data_[zeroCount] == 0) {
            zeroCount++;
        }
        size = zeroCount + (size - zeroCount)*8351/6115+1;
        bytes memory slot = new bytes(size);
        uint32 carry;
        int256 m;
        int256 high = int256(size) - 1;
        for (uint256 i = 0; i < data_.length; i++) {
            m = int256(size - 1);
            for (carry = uint8(data_[i]); m > high || carry != 0; m--) {
                carry = carry + 256 * uint8(slot[uint256(m)]);
                slot[uint256(m)] = bytes1(uint8(carry % 58));
                carry /= 58;
            }
            high = m;
        }
        uint256 n;
        for (n = zeroCount; n < size && slot[n] == 0; n++) {}
        size = slot.length - (n - zeroCount);
        bytes memory out = new bytes(size);
        for (uint256 i = 0; i < size; i++) {
            uint256 j = i + n - zeroCount;
            out[i] = ALPHABET[uint8(slot[j])];
        }
        return out;
    }

    /**
     * @notice cidv0 is used to convert sha256 hash to cid(v0) used by IPFS.
     * @param sha256Hash_ sha256 hash generated by anything.
     * @return IPFS cid that meets the version0 specification.
     */
    function cidv0(bytes32 sha256Hash_) public pure returns (string memory) {
        bytes memory hashString = new bytes(34);
        hashString[0] = 0x12;
        hashString[1] = 0x20;
        for (uint256 i = 0; i < sha256Hash_.length; i++) {
            hashString[i+2] = sha256Hash_[i];
        }
        return string(base58(hashString));
    }
}

/**
 * @title Hootbirds
 * @author HootLabs
 */
contract Hootbirds is Ownable, ReentrancyGuard, Pausable, ERC721, Crypto {
    using Strings for uint256;

    event ProvenanceUpdated(string procenance);
    event MaintainerAddressChanged(address indexed maintainer);
    event BaseURIChanged(string url);
    event TokenHashChanged(uint256 indexed tokenId, bytes32 oldTokenHash, bytes32 newTokenHash);
    event INKEPASSMapURIChanged(string url);
    event AirdropTimeChanged(uint256 airdropTime);
    event RevealTimeChanged(uint256 revealTime);
    event Revealed();
    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event ContractParsed();
    event ContractUnparsed();
    event ContractSealed();

    uint256 public constant MAX_SUPPLY = 1111;

    string public provenance;
    string public inkepassMapURI;
    string private _placeholderURI;
    string private _collectionURI;

    address public maintainerAddress;
    uint256 public airdropTime = 1; // start time to air-drop
    uint256 public revealTime = 1; // start time to reveal
    uint64 public mintedNumber = 0;
    bool public contractSealed = false;
    bool public revealed = false;

    uint256[MAX_SUPPLY] internal _randIndices; // Used to generate random tokenids

    mapping(uint256 => bytes32) private _tokenHashes;

    constructor(string memory placeholderURI_) ERC721("Hootbirds", "IPT") {
        _placeholderURI = placeholderURI_;
    }

    /***********************************|
    |               Provenance          |
    |__________________________________*/
    function setProvenance(string calldata provenance_) external onlyOwner {
        provenance = provenance_;
        emit ProvenanceUpdated(provenance_);
    }

    /***********************************|
    |               Config              |
    |__________________________________*/
    /**
     * @notice setMaintainerAddress is used to allow the issuer to modify the maintainerAddress
     */
    function setMaintainerAddress(address maintainerAddress_) external onlyOwner {
        maintainerAddress = maintainerAddress_;
        emit MaintainerAddressChanged(maintainerAddress_);
    }
    function setAirdropTime(uint256 airdropTime_) external onlyOwner {
        airdropTime = airdropTime_;
        emit AirdropTimeChanged(airdropTime_);
    }

    function isAirdropEnabled() public view returns (bool) {
        return airdropTime > 1 && block.timestamp > airdropTime;
    }

    function setRevealTime(uint256 revealTime_) external onlyOwner {
        revealTime = revealTime_;
        emit RevealTimeChanged(revealTime_);
    }

    /**
     * @notice return is revealed
     */
    function isRevealEnabled() public view returns (bool) {
        return revealTime > 1 && block.timestamp > revealTime;
    }

    function setPlaceholderURI(string calldata uri_) external onlyOwner {
        require(!revealed, "already revealed, can not set placeholder uri");
        _placeholderURI = uri_;
        emit BaseURIChanged(uri_);
    }
    /**
     * @notice set the nft metadata
     * This process is under the supervision of the community.
     */
    function setCollectionURI(string calldata uri_) external onlyOwner {
        _collectionURI = uri_;
        if (revealed) {
            emit BaseURIChanged(uri_);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _collectionURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "query for nonexistent token");
        if (!revealed) {
            return _placeholderURI;
        }
        bytes32 hash = _tokenHashes[tokenId];
        if (hash == "") {
            string memory baseURI = _baseURI();
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
        }
        return string(abi.encodePacked("ipfs://", cidv0(hash)));
    }

    /**
     * set the ipfs url to reach a consensus about the INKEPASS MAP data
     */
    function setINKEPASSMapURI(string calldata uri_) external onlyOwner {
        inkepassMapURI = uri_;
        emit INKEPASSMapURIChanged(uri_);
    }

    /**
     * @notice setTokenHash is used to set the ipfs hash of the token
     * This process is under the supervision of the community.
     */
    function setTokenHash(uint256 tokenId_, bytes32 tokenHash_) public atLeastMaintainer {
        bytes32 oldTokenHash = _tokenHashes[tokenId_];
        _tokenHashes[tokenId_] = tokenHash_;
        emit TokenHashChanged(tokenId_, oldTokenHash, tokenHash_);
    }

    /**
     * @notice similar to setTokenHash, but in bulk
     */
    function batchSetTokenHash(uint256[] calldata tokenIds_, bytes32[] calldata tokenHashes_) external atLeastMaintainer {
        require(tokenIds_.length == tokenHashes_.length, "tokenIds_ and tokenHashes_ length mismatch");
        require(tokenIds_.length > 0, "no tokenId");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            setTokenHash(tokenIds_[i], tokenHashes_[i]);
        }
    }

    /***********************************|
    |               Core                |
    |__________________________________*/
    /**
     * airdrop Hootbirds NFT to receivers who has INKEPASS.
     */
    function airdrop(
        address[] calldata receivers_,
        uint16[] calldata amounts_
    ) external onlyOwner nonReentrant {
        require(
            receivers_.length == amounts_.length,
            "the length of Listing Receiver is different from that of Listing Amounts"
        );
        require(isAirdropEnabled(), "airdrop is not enabled");
        require(mintedNumber < MAX_SUPPLY, "airdrop is already completed");
        unchecked {
            for (uint64 i=0; i < receivers_.length; ++i) {
                airdropToReceiver(receivers_[i], amounts_[i]);
            }
        }
    }
    function airdropToReceiver(address receiverAddr_, uint16 amount_) internal {
        require(amount_ > 0, "mint amount is zero");
        unchecked {
            require(
                mintedNumber + amount_ <= MAX_SUPPLY,
                "minted number is out of MAX_SUPPLY"
            );
            do {
                uint256 tokenId = genRandomTokenId();
                _mint(receiverAddr_, tokenId);
                --amount_;
                ++mintedNumber;
            } while (amount_ > 0);
        }
    }
    /**
     * mint first Hootbirds NFT, then it will be shown on NFT marketplaces.
     */
    function openUpWastedland() external onlyOwner nonReentrant{
        require(mintedNumber==0, "already opened up wastedland");
        changePos(MAX_SUPPLY-1, 0);
        _safeMint(_msgSender(), 1);
        ++mintedNumber;
    }

    /**
     * @notice Flip token metadata to revealed
     * @dev Can only be revealed after airdrop already been completed
     */
    function reveal() external onlyOwner nonReentrant {
        require(!revealed, "already revealed");
        require(mintedNumber == MAX_SUPPLY, "airdrop is not finished yet");
        require(isRevealEnabled(), "reveal is not enabled");
        revealed = true;
        emit BaseURIChanged(_baseURI());
        emit Revealed();
    }

    /**
     * @notice issuer deposit ETH into the contract. only issuer have permission
     */
    function deposit() external payable onlyOwner nonReentrant {
        emit Deposit(_msgSender(), msg.value);
    }
    /**
     * issuer withdraws the ETH temporarily stored in the contract through this method.
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit Withdraw(_msgSender(), balance);
    }
    /**
     * @notice issuer have permission to burn token.
     * @param tokenIds_ list of tokenId
     */
    function burn(uint256[] calldata tokenIds_) external onlyOwner nonReentrant  {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            require(ownerOf(tokenId) == _msgSender(), "caller is not owner");
            _burn(tokenId);
        }
    }

    /***********************************|
    |               RandomTokenId       |
    |__________________________________*/
    function genRandomTokenId() internal returns (uint256) {
        unchecked {
            uint256 remain = MAX_SUPPLY - mintedNumber;
            return changePos(remain-1, unsafeRandom() % remain);
        }
    }
    function changePos(uint256 lastestPos, uint256 pos) internal returns (uint256) {
        uint256 val = _randIndices[pos] == 0 ? pos + 1 : _randIndices[pos];
        _randIndices[pos] = _randIndices[lastestPos] == 0
            ? lastestPos + 1
            : _randIndices[lastestPos];
        return val;
    }

    /***********************************|
    |               Util               |
    |__________________________________*/
    /**
     * @notice unsafeRandom is used to generate a random number by on-chain randomness.
     * Please note that on-chain random is potentially manipulated by miners, and most scenarios suggest using VRF.
     * @return randomly generated number.
     */
    function unsafeRandom() internal view returns (uint256) {
        unchecked {
            return
                uint256(
                    keccak256(
                        abi.encodePacked(
                            blockhash(block.number - 1),
                            block.difficulty,
                            block.timestamp,
                            block.coinbase,
                            mintedNumber,
                            tx.origin
                        )
                    )
                );
        }
    }

    /***********************************|
    |               Beak Raising        |
    |__________________________________*/
    event BeakRaisingStarted(uint256 indexed tokenId, address indexed account);
    event BeakRaisingStopped(uint256 indexed tokenId, address indexed account);
    event BeakRaisingInterrupted(uint256 indexed tokenId);
    event BeakRaisingTokenTransfered(address indexed from, address indexed to, uint256 indexed tokenId);
    event BeakRaisingAllowedFlagChanged(bool isBeakRaisingAllowed);
    event BeakRaisingTransferAllowedFlagChanged(bool isBeakRaisingTransferAllowed);
    struct BeakRaisingStatus {
        uint256 lastStartTime;
        uint256 total;
        bool provisionalFree;
    }
    bool public isBeakRaisingAllowed;
    bool public isBeakRaisingTransferAllowed;
    mapping(uint256 => BeakRaisingStatus) private _beakRaisingStatuses;

    /***********************************|
    |               Beak Raising Config |
    |__________________________________*/
    /**
     * @notice setIsBeakRaisingAllowed is used to set the global switch to control whether users are allowed to brew.
     * @param isBeakRaisingAllowed_ set to true to allow
     */
    function setIsBeakRaisingAllowed(bool isBeakRaisingAllowed_) external onlyOwner {
        isBeakRaisingAllowed = isBeakRaisingAllowed_;
        emit BeakRaisingAllowedFlagChanged(isBeakRaisingAllowed);
    }
    function setIsBeakRaisingTransferAllowed(bool isBeakRaisingTransferAllowed_) external onlyOwner {
        isBeakRaisingTransferAllowed = isBeakRaisingTransferAllowed_;
        emit BeakRaisingTransferAllowedFlagChanged(isBeakRaisingTransferAllowed);
    }

    /***********************************|
    |               Beak Raising Core   |
    |__________________________________*/
    /**
     * @notice safeTransferWhileBeakRaising is used to safely transfer tokens while beak raising
     * @param from_ transfer from address, cannot be the zero.
     * @param to_ transfer to address, cannot be the zero.
     * @param tokenId_ token must exist and be owned by `from`.
     */
    function safeTransferWhileBeakRaising(address from_, address to_, uint256 tokenId_) external nonReentrant {
        require(ownerOf(tokenId_) == _msgSender(), "caller is not owner");
        require(isBeakRaisingTransferAllowed, "transfer while beak raising is not enabled");
        _beakRaisingStatuses[tokenId_].provisionalFree = true;
        safeTransferFrom(from_, to_, tokenId_);
        _beakRaisingStatuses[tokenId_].provisionalFree = false;
        if (_beakRaisingStatuses[tokenId_].lastStartTime != 0) {
            emit BeakRaisingTokenTransfered(from_, to_, tokenId_);
        }
    }

    /**
     * @notice getTokenBeakRaisingStatus is used to get the detailed beak raising status of a specific token.
     * @param tokenId_ token id
     * @return isBeakRaising_ whether the current token is beak raising.
     * @return current_ how long the token has been beak raising in the hands of the current hodler.
     * @return total_ total amount of beak raising since the token minted.
     */
    function getTokenBeakRaisingStatus(uint256 tokenId_) external view returns (bool isBeakRaising_, uint256 current_, uint256 total_) {
        require(_exists(tokenId_), "query for nonexistent token");
        BeakRaisingStatus memory status = _beakRaisingStatuses[tokenId_];
        if (status.lastStartTime != 0) {
            isBeakRaising_ = true;
            current_ = block.timestamp - status.lastStartTime;
        }
        total_ = status.total + current_;
    }

    /**
     * @notice setTokenBeakRaisingState is used to modify the BeakRaising state of the Token, 
     * only the Owner of the Token has this permission.
     * @param tokenIds_ list of tokenId
     */
    function startTokenBeakRaising(uint256[] calldata tokenIds_) external nonReentrant {
        require(isBeakRaisingAllowed, "beak raising is not allowed");
        unchecked {
            for (uint256 i = 0; i < tokenIds_.length; i++) {
                uint256 tokenId = tokenIds_[i];
                require(ownerOf(tokenId) == _msgSender(), "caller is not owner");

                BeakRaisingStatus storage status = _beakRaisingStatuses[tokenId];
                if (status.lastStartTime == 0) {
                    status.lastStartTime = block.timestamp;
                    emit BeakRaisingStarted(tokenId, _msgSender());
                }
            }
        }
    }
    function stopTokenBeakRaising(uint256[] calldata tokenIds_) external nonReentrant {
        unchecked {
            for (uint256 i = 0; i < tokenIds_.length; i++) {
                uint256 tokenId = tokenIds_[i];
                require(ownerOf(tokenId) == _msgSender(), "caller is not owner");

                BeakRaisingStatus storage status = _beakRaisingStatuses[tokenId];
                uint256 lastStartTime = status.lastStartTime;
                if (lastStartTime > 0) {
                    status.total += block.timestamp - lastStartTime;
                    status.lastStartTime = 0;
                    emit BeakRaisingStopped(tokenId, _msgSender());
                }
            }
        }
    }

    /**
     * @notice interruptTokenBeakRaising gives the issuer the right to forcibly interrupt the beak raising state of the token.
     * One scenario of using it is: someone may maliciously place low-priced beak raising tokens on
     * the secondary market (because beak raising tokens cannot be traded).
     * @param tokenIds_ the tokenId list to operate
     */
    function interruptTokenBeakRaising(uint256[] calldata tokenIds_) external atLeastMaintainer {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            require(_exists(tokenId), "operate for nonexistent token");
            BeakRaisingStatus storage status = _beakRaisingStatuses[tokenId];
            if(status.lastStartTime == 0){
                continue;
            }
            unchecked {
                status.total += block.timestamp - status.lastStartTime;
                status.lastStartTime = 0;
            }
            emit BeakRaisingStopped(tokenId, _msgSender());
            emit BeakRaisingInterrupted(tokenId);
        }
    }

    /***********************************|
    |               Pause               |
    |__________________________________*/

    /**
     * @notice hook function, used to intercept the transfer of token.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(!paused(), "token transfer paused");
        if (!_beakRaisingStatuses[tokenId].provisionalFree) {
            require(_beakRaisingStatuses[tokenId].lastStartTime == 0, "token is beak raising");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice for the purpose of protecting user assets, under extreme conditions,
     * the circulation of all tokens in the contract needs to be frozen.
     * This process is under the supervision of the community.
     */
    function emergencyPause() external onlyOwner notSealed {
        _pause();
        emit ContractParsed();
    }

    /**
     * @notice unpause the contract
     */
    function unpause() external onlyOwner notSealed {
        _unpause();
        emit ContractUnparsed();
    }

    /**
     * @notice when the project is stable enough, the issuer will call sealContract
     * to give up the permission to call emergencyPause and unpause.
     */
    function sealContract() external onlyOwner {
        contractSealed = true;
        emit ContractSealed();
    }

    /***********************************|
    |               Modifier               |
    |__________________________________*/
    /**
     * @notice for security reasons, CA is not allowed to call sensitive methods.
     */
    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "caller is another contract");
        _;
    }

    /**
     * @notice function call is only allowed when the contract has not been sealed
     */
    modifier notSealed() {
        require(!contractSealed, "contract sealed");
        _;
    }
    /**
     * @notice only owner or maintainer has the permission to call this method
     */
    modifier atLeastMaintainer() {
        require(owner() == _msgSender() || 
            (maintainerAddress != address(0) && maintainerAddress == _msgSender()), 
            "not authorized");
        _;
    }
}