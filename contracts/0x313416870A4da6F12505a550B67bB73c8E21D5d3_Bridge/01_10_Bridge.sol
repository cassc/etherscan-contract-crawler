// SPDX-License-Identifier: Apache 2.0

pragma solidity =0.8.17;

import "./MasterToken.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./SafeERC20.sol";
import "./EthTokenReciever.sol";

/**
 * Provides functionality of the HASHI bridge
 */
contract Bridge is EthTokenReciever {
    using SafeERC20 for IERC20;

    bool internal initialized_;
    bool internal preparedForMigration_;

    mapping(address => bool) public isPeer;
    uint256 public peersCount;

    /** Substrate proofs used */
    mapping(bytes32 => bool) public used;
    mapping(address => bool) public _uniqueAddresses;

    /** White list of ERC-20 ethereum native tokens */
    mapping(address => bool) public acceptedEthTokens;

    /** White lists of ERC-20 SORA native tokens
     * We use several representations of the white list for optimisation purposes.
     */
    mapping(bytes32 => address) public _sidechainTokens;
    mapping(address => bytes32) public _sidechainTokensByAddress;
    address[] public _sidechainTokenAddressArray;

    /**
     * For XOR and VAL use old token contracts, created for SORA 1 bridge.
     * Also for XOR and VAL transfers from SORA 2 to Ethereum old bridges will be used.
     */
    address public immutable _addressVAL;
    address public immutable _addressXOR;
    /** EVM netowrk ID */
    bytes32 public immutable _networkId;

    event Withdrawal(bytes32 txHash);
    event Deposit(
        bytes32 destination,
        uint256 amount,
        address token,
        bytes32 sidechainAsset
    );
    event ChangePeers(address peerId, bool removal);
    event PreparedForMigration();
    event Migrated(address to);

    /**
     * Constructor.
     * @param initialPeers - list of initial bridge validators on substrate side.
     * @param addressVAL address of VAL token Contract
     * @param addressXOR address of XOR token Contract
     * @param networkId id of current EvM network used for bridge purpose.
     */
    constructor(
        address[] memory initialPeers,
        address[] memory sidechainTokenAddresses,
        bytes32[] memory sidechainAssetIds,
        address[] memory erc20Addresses,
        address addressVAL,
        address addressXOR,
        bytes32 networkId
    ) {
        require(
            sidechainAssetIds.length == sidechainTokenAddresses.length,
            "Length mismatch"
        );

        for (uint256 i; i < initialPeers.length; i++) {
            addPeer(initialPeers[i]);
        }
        _addressXOR = addressXOR;
        _addressVAL = addressVAL;
        _networkId = networkId;
        initialized_ = true;

        acceptedEthTokens[addressXOR] = true;
        acceptedEthTokens[addressVAL] = true;

        for (uint256 i; i < sidechainTokenAddresses.length; i++) {
            address tokenAddress = sidechainTokenAddresses[i];
            bytes32 assetId = sidechainAssetIds[i];
            _sidechainTokens[assetId] = tokenAddress;
            _sidechainTokensByAddress[tokenAddress] = assetId;
            _sidechainTokenAddressArray.push(tokenAddress);
        }
        uint256 erc20TokensCount = erc20Addresses.length;
        for (uint256 i; i < erc20TokensCount; i++) {
            acceptedEthTokens[erc20Addresses[i]] = true;
        }
    }

    modifier shouldBeInitialized() {
        require(
            initialized_ == true,
            "Contract should be initialized to use this function"
        );
        _;
    }

    modifier shouldNotBePreparedForMigration() {
        require(
            preparedForMigration_ == false,
            "Contract should not be prepared for migration to use this function"
        );
        _;
    }

    modifier shouldBePreparedForMigration() {
        require(
            preparedForMigration_ == true,
            "Contract should be prepared for migration to use this function"
        );
        _;
    }

    fallback() external {
        revert();
    }

    receive() external payable {
        revert();
    }

    /*
    Used only for migration
    */
    function receivePayment() external payable override {}

    /**
     * Adds new token to whitelist.
     * Token should not been already added.
     *
     * @param newToken new token contract address
     * @param ticker token ticker (symbol)
     * @param name token title
     * @param decimals count of token decimal places
     * @param txHash transaction hash from sidechain
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function addEthNativeToken(
        address newToken,
        string memory ticker,
        string memory name,
        uint8 decimals,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external shouldBeInitialized {
        require(used[txHash] == false, "txHash already used");
        require(
            acceptedEthTokens[newToken] == false,
            "ERC20 token is not whitelisted"
        );
        require(
            checkSignatures(
                keccak256(
                    abi.encode(
                        "addToken",
                        address(this),
                        newToken,
                        ticker,
                        name,
                        decimals,
                        txHash,
                        _networkId
                    )
                ),
                v,
                r,
                s
            ),
            "Peer signatures are invalid"
        );
        used[txHash] = true;
        acceptedEthTokens[newToken] = true;
    }

    /**
     * Preparations for migration to new Bridge contract
     *
     * @param salt unique data used for signature
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function prepareForMigration(
        bytes32 salt,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external shouldBeInitialized shouldNotBePreparedForMigration {
        require(used[salt] == false, "txHash already used");
        require(
            checkSignatures(
                keccak256(
                    abi.encode(
                        "prepareMigration",
                        address(this),
                        salt,
                        _networkId
                    )
                ),
                v,
                r,
                s
            ),
            "Peer signatures are invalid"
        );
        used[salt] = true;
        preparedForMigration_ = true;
        emit PreparedForMigration();
    }

    /**
     * Shutdown this contract and migrate tokens ownership to the new contract.
     *
     * @param salt unique data used for signature generation
     * @param newContractAddress address of the new bridge contract
     * @param erc20nativeTokens list of ERC20 tokens with non zero balances for this contract. Can be taken from substrate bridge peers.
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function shutDownAndMigrate(
        bytes32 salt,
        address payable newContractAddress,
        address[] calldata erc20nativeTokens,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external shouldBeInitialized shouldBePreparedForMigration {
        require(used[salt] == false, "txHash already used");
        require(
            checkSignatures(
                keccak256(
                    abi.encode(
                        "migrate",
                        address(this),
                        newContractAddress,
                        salt,
                        erc20nativeTokens,
                        _networkId
                    )
                ),
                v,
                r,
                s
            ),
            "Peer signatures are invalid"
        );
        used[salt] = true;
        uint256 sidechainTokensCount = _sidechainTokenAddressArray.length;
        for (uint256 i; i < sidechainTokensCount; i++) {
            Ownable token = Ownable(_sidechainTokenAddressArray[i]);
            token.transferOwnership(newContractAddress);
        }
        uint256 erc20nativeTokensCount = erc20nativeTokens.length;
        for (uint256 i; i < erc20nativeTokensCount; i++) {
            IERC20 token = IERC20(erc20nativeTokens[i]);
            token.safeTransfer(
                newContractAddress,
                token.balanceOf(address(this))
            );
        }
        EthTokenReciever(newContractAddress).receivePayment{
            value: address(this).balance
        }();
        initialized_ = false;
        emit Migrated(newContractAddress);
    }

    /**
     * Add new token from sidechain to the bridge white list.
     *
     * @param name token title
     * @param symbol token symbol
     * @param decimals number of decimals
     * @param sidechainAssetId token id on the sidechain
     * @param txHash sidechain transaction hash
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function addNewSidechainToken(
        string memory name,
        string memory symbol,
        uint8 decimals,
        bytes32 sidechainAssetId,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external shouldBeInitialized {
        require(used[txHash] == false, "txHash already used");
        require(
            checkSignatures(
                keccak256(
                    abi.encode(
                        "addAsset",
                        address(this),
                        name,
                        symbol,
                        decimals,
                        sidechainAssetId,
                        txHash,
                        _networkId
                    )
                ),
                v,
                r,
                s
            ),
            "Peer signatures are invalid"
        );
        used[txHash] = true;
        // Create new instance of the token
        MasterToken tokenInstance = new MasterToken(
            name,
            symbol,
            decimals,
            address(this),
            0,
            sidechainAssetId
        );
        address tokenAddress = address(tokenInstance);
        _sidechainTokens[sidechainAssetId] = tokenAddress;
        _sidechainTokensByAddress[tokenAddress] = sidechainAssetId;
        _sidechainTokenAddressArray.push(tokenAddress);
    }

    /**
     * Send Ethereum to sidechain.
     *
     * @param to destionation address on sidechain.
     */
    function sendEthToSidechain(bytes32 to)
        external
        payable
        shouldBeInitialized
        shouldNotBePreparedForMigration
    {
        require(msg.value > 0, "ETH VALUE SHOULD BE MORE THAN 0");
        bytes32 empty;
        emit Deposit(to, msg.value, address(0x0), empty);
    }

    /**
     * Send ERC-20 token to sidechain.
     *
     * @param to destination address on the sidechain
     * @param amount amount to sendERC20ToSidechain
     * @param tokenAddress contract address of token to send
     */
    function sendERC20ToSidechain(
        bytes32 to,
        uint256 amount,
        address tokenAddress
    ) external shouldBeInitialized shouldNotBePreparedForMigration {
        IERC20 token = IERC20(tokenAddress);

        bytes32 sidechainAssetId = _sidechainTokensByAddress[tokenAddress];
        if (
            sidechainAssetId != "" ||
            _addressVAL == tokenAddress ||
            _addressXOR == tokenAddress
        ) {
            ERC20Burnable mtoken = ERC20Burnable(tokenAddress);
            mtoken.burnFrom(msg.sender, amount);
        } else {
            require(
                acceptedEthTokens[tokenAddress],
                "The Token is not accepted for transfer to sidechain"
            );
            uint256 balanceBefore = token.balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), amount);
            uint256 balanceAfter = token.balanceOf(address(this));
            require(
                balanceAfter - balanceBefore >= amount,
                "Not enough tokens transferred"
            );
        }
        emit Deposit(to, amount, tokenAddress, sidechainAssetId);
    }

    /**
     * Add new peer using peers quorum.
     *
     * @param newPeerAddress address of the peer to add
     * @param txHash tx hash from sidechain
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function addPeerByPeer(
        address newPeerAddress,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external shouldBeInitialized returns (bool) {
        require(used[txHash] == false, "txHash already used");
        require(
            checkSignatures(
                keccak256(
                    abi.encode(
                        "addPeer",
                        address(this),
                        newPeerAddress,
                        txHash,
                        _networkId
                    )
                ),
                v,
                r,
                s
            ),
            "Peer signatures are invalid"
        );
        used[txHash] = true;

        addPeer(newPeerAddress);
        emit ChangePeers(newPeerAddress, false);
        return true;
    }

    /**
     * Remove peer using peers quorum.
     *
     * @param peerAddress address of the peer to remove
     * @param txHash tx hash from sidechain
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function removePeerByPeer(
        address peerAddress,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external shouldBeInitialized returns (bool) {
        require(used[txHash] == false, "txHash already used");
        require(
            checkSignatures(
                keccak256(
                    abi.encode(
                        "removePeer",
                        address(this),
                        peerAddress,
                        txHash,
                        _networkId
                    )
                ),
                v,
                r,
                s
            ),
            "Peer signatures are invalid"
        );
        used[txHash] = true;

        removePeer(peerAddress);
        emit ChangePeers(peerAddress, true);
        return true;
    }

    /**
     * Withdraws specified amount of ether or one of ERC-20 tokens to provided sidechain address
     * @param tokenAddress address of token to withdraw (0 for ether)
     * @param amount amount of tokens or ether to withdraw
     * @param to target account address
     * @param txHash hash of transaction from sidechain
     * @param from source of transfer
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function receiveByEthereumAssetAddress(
        address tokenAddress,
        uint256 amount,
        address payable to,
        address from,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external shouldBeInitialized {
        require(used[txHash] == false, "txHash already used");
        require(
            checkSignatures(
                keccak256(
                    abi.encode(
                        "transfer",
                        address(this),
                        tokenAddress,
                        amount,
                        to,
                        from,
                        txHash,
                        _networkId
                    )
                ),
                v,
                r,
                s
            ),
            "Peer signatures are invalid"
        );
        used[txHash] = true;

        if (tokenAddress == address(0)) {
            // untrusted transfer, relies on provided cryptographic proof
            to.transfer(amount);
        } else {
            IERC20 coin = IERC20(tokenAddress);
            // untrusted call, relies on provided cryptographic proof
            coin.safeTransfer(to, amount);
        }
        emit Withdrawal(txHash);
    }

    /**
     * Mint new Token
     * @param sidechainAssetId id of sidechainToken to mint
     * @param amount how much to mint
     * @param to destination address
     * @param from sender address
     * @param txHash hash of transaction from Iroha
     * @param v array of signatures of tx_hash (v-component)
     * @param r array of signatures of tx_hash (r-component)
     * @param s array of signatures of tx_hash (s-component)
     */
    function receiveBySidechainAssetId(
        bytes32 sidechainAssetId,
        uint256 amount,
        address to,
        address from,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external shouldBeInitialized {
        require(
            _sidechainTokens[sidechainAssetId] != address(0x0),
            "Sidechain asset is not registered"
        );
        require(used[txHash] == false, "txHash already used");
        require(
            checkSignatures(
                keccak256(
                    abi.encode(
                        "transferOwned",
                        address(this),
                        sidechainAssetId,
                        amount,
                        to,
                        from,
                        txHash,
                        _networkId
                    )
                ),
                v,
                r,
                s
            ),
            "Peer signatures are invalid"
        );
        used[txHash] = true;

        MasterToken tokenInstance = MasterToken(
            _sidechainTokens[sidechainAssetId]
        );
        tokenInstance.mintTokens(to, amount);
        emit Withdrawal(txHash);
    }

    /**
     * Checks given addresses for duplicates and if they are peers signatures
     * @param hash unsigned data
     * @param v v-component of signature from hash
     * @param r r-component of signature from hash
     * @param s s-component of signature from hash
     * @return true if all given addresses are correct or false otherwise
     */
    function checkSignatures(
        bytes32 hash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) private returns (bool) {
        require(peersCount >= 1, "peersCount too low");
        uint256 signatureCount = v.length;
        require(
            signatureCount == r.length,
            "signatureCount and r length mismatch"
        );
        require(
            signatureCount == s.length,
            "signatureCount and s length mismatch"
        );
        uint256 needSigs = peersCount - (peersCount - 1) / 3;
        require(signatureCount >= needSigs, "not enough signatures");

        uint256 count;
        address[] memory recoveredAddresses = new address[](signatureCount);
        for (uint256 i; i < signatureCount; ++i) {
            address recoveredAddress = recoverAddress(hash, v[i], r[i], s[i]);

            // not a peer address or not unique
            if (
                isPeer[recoveredAddress] != true ||
                _uniqueAddresses[recoveredAddress] == true
            ) {
                continue;
            }
            recoveredAddresses[count] = recoveredAddress;
            unchecked {
                count = count + 1;
            }
            _uniqueAddresses[recoveredAddress] = true;
        }

        // restore state for future usages
        for (uint256 i; i < count; ++i) {
            _uniqueAddresses[recoveredAddresses[i]] = false;
        }

        return count >= needSigs;
    }

    /**
     * Recovers address from a given single signature
     * @param hash unsigned data
     * @param v v-component of signature from hash
     * @param r r-component of signature from hash
     * @param s s-component of signature from hash
     * @return address recovered from signature
     */
    function recoverAddress(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private pure returns (address) {
        bytes32 simple_hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address res = ecrecover(simple_hash, v, r, s);
        return res;
    }

    /**
     * Adds new peer to list of signature verifiers.
     * Internal function
     * @param newAddress address of new peer
     */
    function addPeer(address newAddress) internal returns (uint256) {
        require(isPeer[newAddress] == false, "peer already added");
        isPeer[newAddress] = true;
        ++peersCount;
        return peersCount;
    }

    function removePeer(address peerAddress) internal {
        require(isPeer[peerAddress] == true, "peer does not exists");
        isPeer[peerAddress] = false;
        --peersCount;
    }
}