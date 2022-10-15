// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IDepositContract.sol";
import "../interfaces/IValidatorNft.sol";
import "../interfaces/INodeRewardVault.sol";

/** 
 * @title Router for Validator NFT Strategy
 * @notice Routes incoming data to various Validator NFT Strategies such as trading, minting & more.
 */
contract ValidatorNftRouter is Initializable {
    event NodeTrade(uint256 _tokenId, address _from, address _to, uint256 _amount);
    event Eth32Deposit(bytes _pubkey, bytes _withdrawal, address _owner);

    IValidatorNft public nftContract;
    INodeRewardVault public vault;
    IDepositContract public depositContract;

    address public nftAddress;
    mapping(uint256 => uint64) public nonces;

    function __ValidatorNftRouter__init(address depositContract_, address vault_, address nftContract_) internal onlyInitializing {
        depositContract = IDepositContract(depositContract_);
        vault = INodeRewardVault(vault_);
        nftContract = IValidatorNft(nftContract_);
        nftAddress = nftContract_;
    }

    /**
     * @notice Pre-processing before performing the signer verification.  
     * @return bytes32 hashed value of the pubkey, withdrawalCredentials, signature,
     *         depositDataRoot, bytes32(blockNumber)
     */
    //slither-disable-next-line calls-loop
    function precheck(bytes calldata data) private view returns (bytes32) {
        bytes calldata pubkey = data[16:64];
        bytes calldata withdrawalCredentials = data[64:96];
        bytes calldata signature = data[96:192];
        bytes32 depositDataRoot = bytes32(data[192:224]);
        uint256 blockNumber = uint256(bytes32(data[224:256]));

        require(!nftContract.validatorExists(pubkey), "Pub key already in used");
        require(blockNumber > block.number, "Block height too old, please generate a new transaction");

        return keccak256(abi.encodePacked(pubkey, withdrawalCredentials, signature, depositDataRoot, bytes32(blockNumber)));
    }

    /**
     * @notice Performs signer verification to prevent unauthorized usage
     * @param v, r, and s parts of a signature
     * @param hash_ - hashed value from precheck
     * @param signer_ - authentic signer to check against
     */
    function signercheck(bytes32 s, bytes32 r, uint8 v, bytes32 hash_, address signer_) private pure {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash_));
        address signer = ecrecover(prefixedHash, v, r, s);

        require(signer == signer_, "Not authorized");
        require(signer != address(0), "ECDSA: invalid signature");
    }

    /**
     * @notice Routes incoming data (Trade Strategy) to outbound contracts, ETH2 Official Deposit Contract 
     *         and calls internal functions for pre-processing and signer verfication
     *         check for expired transaction through block height
     * @return uint256 sum of the trades
     */
    //slither-disable-next-line calls-loop
    function _tradeRoute(bytes calldata data) private returns (uint256) {
        require(address(bytes20(data[12:32])) == msg.sender, "Not allowed to make this trade");
        require(uint256(bytes32(data[96:128])) > block.number, "Trade has expired");

        uint256 sum = 0;
        uint256 i = 0;

        for (i = 0; i < uint256(bytes32(data[128:160])); i++) {
            uint256 price = uint256(bytes32(data[160 + i * 224:192 + i * 224]));
            uint256 tokenId = uint256(bytes32(data[192 + i * 224:224 + i * 224]));
            uint256 rebate = uint256(bytes32(data[224 + i * 224:256 + i * 224]));
            uint256 expiredHeight = uint256(bytes32(data[256 + i * 224:288 + i * 224]));
            address signer = address(bytes20(data[352 + i * 224:372 + i * 224]));
            uint64 nonce = uint64(bytes8(data[376 + i * 224:384 + i * 224]));

            require(expiredHeight > block.number, "Listing has expired");
            require(nftContract.ownerOf(tokenId) == signer, "Not owner");
            require(nonce == nonces[tokenId], "Incorrect nonce");
            
            nonces[tokenId]++;
            sum += price;

            bytes32 hash = keccak256(abi.encodePacked(tokenId, rebate, expiredHeight, nonce));
            signercheck(bytes32(data[320 + i * 224:352 + i * 224]), bytes32(data[288 + i * 224:320 + i * 224]), uint8(bytes1(data[372 + i * 224])), hash, signer);
            
            uint256 nodeCapital = nftContract.nodeCapitalOf(tokenId);
            uint256 userPrice = price;
            if (price > nodeCapital) {
                userPrice = price - (price - nodeCapital) * vault.comission() / 10000;
                payable(vault.dao()).transfer(price - userPrice);
            }
            require(userPrice > 30 ether, "Node too cheap");

            payable(signer).transfer(userPrice);
            nftContract.safeTransferFrom(signer, msg.sender, tokenId);
            nftContract.updateNodeCapital(tokenId, price);
            
            emit NodeTrade(tokenId, signer, msg.sender, price);
        }

        bytes32 authHash = keccak256(abi.encodePacked(data[160:], uint256(bytes32(data[96:128])), msg.sender));
        signercheck(bytes32(data[64:96]), bytes32(data[32:64]), uint8(bytes1(data[1])), authHash, vault.authority());

        return sum;
    }

    /**
     * @notice Allows transfer funds of 32 ETH to the ETH2 Official Deposit Contract
     */
    //slither-disable-next-line reentrancy-events
    function deposit(bytes calldata data) private {
        bytes calldata pubkey = data[16:64];
        bytes calldata withdrawalCredentials = data[64:96];
        bytes calldata signature = data[96:192];
        bytes32 depositDataRoot = bytes32(data[192:224]);

        depositContract.deposit{value: 32 ether}(pubkey, withdrawalCredentials, signature, depositDataRoot);
        
        emit Eth32Deposit(pubkey, withdrawalCredentials, msg.sender);
    }

    /**
     * @notice Routes incoming data(ETH32 Strategy) to outbound contracts, ETH2 Official Deposit Contract 
     *         and calls internal functions for pre-processing and signer verfication, minting of nft to user.
     */
    //slither-disable-next-line calls-loop
    function eth32Route(bytes calldata data) internal returns (bool) {
        bytes32 hash = precheck(data);
        signercheck(bytes32(data[256:288]), bytes32(data[288:320]), uint8(bytes1(data[1])), hash, vault.authority());
        deposit(data);

        vault.settle();
        nftContract.whiteListMint(data[16:64], msg.sender);

        return true;
    }

    /**
     * @notice Routes incoming data(Trade Strategy) to outbound contracts, ETH2 Official Deposit Contract 
     *         and calls internal functions for pre-processing and signer verfication
     *         check for expired transaction through block height
     * @return uint256 sum of the trades
     */
    function tradeRoute(bytes calldata data) internal returns (uint256) {
        return _tradeRoute(data);
    }

    /**
     * @dev See {IAggregator-disperseRewards}.
     */
    //slither-disable-next-line reentrancy-events
    function rewardRoute(uint256 tokenId) internal {
        vault.claimRewards(tokenId);
        nftContract.setGasHeight(tokenId, vault.rewardsHeight());
    }
}