/*


            .':looooc;.    .,cccc,.    'cccc:. 'ccccc:. .:ccccccccccccc:. .:ccc:.    .;cccc,        
          .lOXNWWWNWNNKx;. .kWNNWk.    lNWNWK, dWWWNWX; :XWNWNNNNNWNWWWX: :XWNWX:    .OWNNWd.       
         ;0NNNNNXKXNNNNNXd..kWNNWk.    lNNNWK, oNNNNWK; :KWNNNNNNNNNNNN0, :XWNWX:    .OWNNNd.       
        ;0WNNN0c,.';x0Oxoc..kWNNW0c;:::xNNNWK, oNNNNWK; .;;;;:dKNNNNNXd'  :XWNWX:    .OWNNNd.       
       .oNNNWK;     ...    .kWNNNNNNNNNNNNNWK, :0NWNXx'     .l0NNNNNk;.   :XWNWX:    .OWNNNd.       
       .oNNNWK;     ...    .kWNNNNNWWWWNNNNWK,  .,c:'.    .;ONNNNN0c.     :XWNWXc    'OWNNNd.       
        ;0NNNN0l,.':xKOkdc..kWNNW0occcckNNNWK, .:oddo,.  'xXNNNNNKo::::;. '0WNNN0c,,:xXNNWXc        
         ;0NNNNNXKXNNNNNXo..kWNNWk.    lNNNWK,.oNNNNWK; :KNNNNNNNNNNNNNXc  :KNNNNNNXNNNNNNd.        
          .lkXNWNNWWNNKx;. .kWNNWk.    lNWNWK, :KNWNNk' oNWNNWNNNNNWNNWNc   ,dKNWWNNWWNXk:.         
            .':looolc;.    .,c::c,.    ':::c;.  .:c:,.  ':c::c:::c::::c:.     .;coodol:'.           


*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libs/interfaces/IMigrateable.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./libs/users/AddressManagerNode.sol";
import "./libs/nfts/ERC721Core.sol";
import "./libs/nfts/ERC721Creator.sol";
import "./libs/nfts/ERC721Metadata.sol";
import "./libs/nfts/ERC721Mint.sol";
import "./libs/nfts/ERC721ProxyCall.sol";
import "./libs/nfts/ERC721Royalty.sol";
import "./libs/OZ/ERC165UpgradeableGap.sol";
import "./libs/OZ/OZERC721Upgradeable.sol";
import "./libs/OZ/OZERC165Checker.sol";

error CHZIUERC721_Not_Support_Interface();
error CHZIUERC721_Can_Not_Migrate_To_ADDRESS_0();
error CHZIUERC721_Can_Not_Move_To_Same_Collection();
error CHZIUERC721_Holder_Is_Not_Creator();
error CHZIUERC721_Over_Than_Limit_Numer();
error CHZIUERC721_Time_Expired();

/**
 * @title CHIZU NFTs implemented using the ERC-721 standard.
 */
contract CHIZUERC721 is
    Initializable,
    ERC721Core,
    ERC165UpgradeableGap,
    ERC165,
    ERC721Royalty,
    ERC721Mint
{
    using OZERC165Checker for address;
    using ECDSA for bytes32;

    /// @notice Maximum amount that can be migrated
    uint256 constant MAX_MIGRATE_NUMBER = 20;

    /**
     * @notice Emitted when a NFT is migrated.
     * @param tokenId The tokenId to migrate
     * @param ipfsHash The ipfsHash of the migrated NFT
     * @param from Account sending nft
     * @param to Account receiving nft
     * @param salt Random number value used in the transaction
     */
    event Migrated(
        uint256 tokenId,
        uint256 policy,
        string ipfsHash,
        address from,
        address to,
        uint256 salt
    );

    /**
     * @dev Initialize function for upgradeable
     * @param _core The address of the contract defining roles for collections to use.
     */
    function initialize(address _core) external initializer {
        OZERC721Upgradeable.__ERC721_init(_core);
        ERC721Mint._initializeERC721Mint(_core);
        AddressManagerNode.AddressManagerNode_init(payable(_core));
    }

    /**
     * @notice Allows a CHIZU admin to update NFT config variables.
     * @dev This must be called right after the initial call to `initialize`.
     */
    function adminUpdateConfig(
        address _core,
        string calldata baseURI,
        address proxyCallContract
    ) external onlyCHIZUAdmin {
        _setCore(payable(_core));
        _updateBaseURI(baseURI);
        _updateProxyCall(proxyCallContract);
    }

    /**
     * @notice Function used by the sender of token in migrate
     * @dev The Contract to send is address(this)
     * @param validateInfo Structure to verify the signature for migrate
     * @param signerInfo Information about signature
     * @param tokenIdArrayFrom Array of sending tokens
     * @param to The account of the receiving user
     * @param salt Valid Random Value for Transaction
     * @return original Information on the tokens to send
     */
    function migrateFrom(
        IMigrateable.ValidateInfo[] memory validateInfo,
        IMigrateable.SignerInfo memory signerInfo,
        uint256[] memory tokenIdArrayFrom,
        address to,
        uint256 salt,
        uint256 expiredAt
    ) public returns (IMigrateable.TokenData[] memory) {
        if (tokenIdArrayFrom.length > MAX_MIGRATE_NUMBER) {
            revert CHZIUERC721_Over_Than_Limit_Numer();
        }

        if (to == address(0)) {
            revert CHZIUERC721_Can_Not_Migrate_To_ADDRESS_0();
        }
        if (to == address(this)) {
            revert CHZIUERC721_Can_Not_Move_To_Same_Collection();
        }

        uint256[] memory slice = _exportMigrateSlice(tokenIdArrayFrom);

        for (uint256 i = 0; i < slice.length; i++) {
            bool success = _validateMigrateSignature(
                validateInfo[i],
                slice[i],
                signerInfo,
                address(this),
                to,
                salt,
                expiredAt
            );
            require(success, "CHZIUERC721 : Signature is wrong");
        }

        IMigrateable.TokenData[] memory original = new IMigrateable.TokenData[](
            tokenIdArrayFrom.length
        );

        for (uint256 j = 0; j < tokenIdArrayFrom.length; j++) {
            if (
                ownerOf(tokenIdArrayFrom[j]) !=
                tokenCreator(tokenIdArrayFrom[j])
            ) {
                revert CHZIUERC721_Holder_Is_Not_Creator();
            }
            original[j].IPFSHash = getTokenIPFSHash(tokenIdArrayFrom[j]);
            original[j].policy = getPolicyOfToken(tokenIdArrayFrom[j]);
            _burn(tokenIdArrayFrom[j]);
        }
        return original;
    }

    /**
     * @notice Function used by the receiver of token in migrate
     * @dev The Contract to receive is address(this)
     * @param validateInfo Structure to verify the signature for migrate
     * @param signerInfo Information about signature
     * @param tokenIdArrayFrom Array of sending tokens
     * @param from The account of the sender
     * @param salt Valid Random Value for Transaction
     * @return tokenIdArrayTo tokenIds minted in the contract receiving the token
     */
    function migrate(
        IMigrateable.ValidateInfo[] memory validateInfo,
        IMigrateable.SignerInfo memory signerInfo,
        uint256[] memory tokenIdArrayFrom,
        address from,
        uint256 salt,
        uint256 expiredAt
    ) public returns (uint256[] memory) {
        if (expiredAt < block.timestamp) {
            revert CHZIUERC721_Time_Expired();
        }
        if (!from.supportsInterface(type(IMigrateable).interfaceId)) {
            revert CHZIUERC721_Not_Support_Interface();
        }
        IMigrateable.TokenData[] memory original = IMigrateable(from)
            .migrateFrom(
                validateInfo,
                signerInfo,
                tokenIdArrayFrom,
                address(this),
                salt,
                expiredAt
            );

        uint256[] memory tokenIdArrayTo = new uint256[](
            tokenIdArrayFrom.length
        );

        for (uint256 i = 0; i < tokenIdArrayFrom.length; i++) {
            unchecked {
                // Number of tokens cannot overflow 256 bits.
                tokenIdArrayTo[i] = ++lastTokenId;
            }
            _mint(msg.sender, tokenIdArrayTo[i]);
            _setTokenIPFSHash(tokenIdArrayTo[i], original[i].IPFSHash);
            _setTokenPolicy(tokenIdArrayTo[i], original[i].policy);
            emit Migrated(
                tokenIdArrayFrom[i],
                original[i].policy,
                original[i].IPFSHash,
                from,
                address(this),
                salt
            );
        }
        return tokenIdArrayTo;
    }

    /**
     * @dev Functions that validate migrateSignature
     * @dev userSignature is signature of receiver
     */
    function _validateMigrateSignature(
        IMigrateable.ValidateInfo memory validateInfo,
        uint256 slice,
        IMigrateable.SignerInfo memory signerInfo,
        address from,
        address to,
        uint256 salt,
        uint256 expiredAt
    ) internal pure returns (bool success) {
        bytes32 calculatedHash = keccak256(
            abi.encodePacked(
                uint256(salt),
                uint256(slice),
                uint256(uint160(from)),
                uint256(uint160(to)),
                uint256(expiredAt)
            )
        );
        bytes32 calculatedOrigin = keccak256(
            abi.encodePacked(
                //ethereum signature prefix
                "\x19Ethereum Signed Message:\n32",
                //Orderer
                uint256(calculatedHash)
            )
        );
        address recoveredNodeSigner = calculatedOrigin.recover(
            validateInfo.nodeSignature
        );

        address recoveredUserSigner = calculatedOrigin.recover(
            validateInfo.userSignature
        );

        if (calculatedHash != validateInfo.finalHash) {
            return false;
        }
        if (recoveredNodeSigner != signerInfo.nodeAddress) {
            return false;
        }
        if (recoveredUserSigner != signerInfo.userAddress) {
            return false;
        }
        return true;
    }

    /**
     * @dev Function that creates slice by pasting tokenId for tokenId verification
     */
    function _exportMigrateSlice(uint256[] memory tokenIdArray)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 tokenIdSlice;
        uint256 count;
        uint256 index;
        uint256[] memory sliceArray = new uint256[](3);
        for (uint256 i = 0; i < tokenIdArray.length; i++) {
            tokenIdSlice = (tokenIdSlice << 32) | tokenIdArray[i];
            if (i == tokenIdArray.length - 1) {
                sliceArray[index] = tokenIdSlice;
                break;
            }
            ++count;
            if (count == 8) {
                count = 0;
                sliceArray[index] = tokenIdSlice;
                tokenIdSlice = 0;
                index++;
            }
        }
        return sliceArray;
    }

    /**
     * @dev This is a no-op, just an explicit override to address compile errors due to inheritance.
     */
    function _burn(uint256 tokenId)
        internal
        override(ERC721Creator, ERC721Mint)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, ERC721Mint, ERC721Royalty)
        returns (bool)
    {
        if (interfaceId == type(IMigrateable).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    uint256[1000] private __gap;
}