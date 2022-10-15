// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// LIBRARIES
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
// INTERFACES
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// ABSTRACT CONTRACTS
import "@openzeppelin/contracts/utils/Context.sol";
import "solmate/src/tokens/ERC1155.sol";
import "solmate/src/auth/Owned.sol";

/// @title Token contract implementing ERC1155.
/// @author Ahmed Ali <github.com/ahmedali8>
contract Token is Context, Owned, ERC1155 {
    using Counters for Counters.Counter;

    /*//////////////////////////////////////////////////////////////
                                VARIABLES
    //////////////////////////////////////////////////////////////*/

    Counters.Counter private _tokenIdTracker;

    enum NFTType {
        ERC721,
        ERC1155
    }

    struct Own {
        NFTType nftType;
        address nftAddress;
        uint256 tokenId;
        uint256 amount;
    }

    struct Burn {
        uint256 tokenId;
        uint256 amount;
    }

    struct InitializeTokenIdParams {
        uint32 startTime;
        uint32 endTime; // 0 means it's unlimited
        uint256 price; // 0 means it's free
        uint256 maxSupply; // 0 means it's unlimited
        uint256 amountPerAccount; // 0 means it's unlimited mints per account
        string metadata;
        Burn[] burnInfos;
        Own[] ownInfos;
    }

    struct TokenInfo {
        bool exists;
        bool isBurningRequired;
        bool isOwningRequired;
        uint32 startTime;
        uint32 endTime; // endTime 0 means it's unlimited
        uint256 price; // price 0 means it's free
        uint256 totalSupply;
        uint256 maxSupply; // maxSupply 0 means it's unlimited
        uint256 amountPerAccount; // amountPerAccount 0 means it's unlimited mints per account
        string metadata;
        Burn[] burnInfos;
        Own[] ownInfos;
    }

    /// @dev Mapping to track TokenInfo of each tokenId.
    /// id -> TokenInfo
    mapping(uint256 => TokenInfo) private p_tokenInfo;
    // solhint-disable-previous-line var-name-mixedcase

    /// @dev Mapping to track burn balance of each account's tokenId.
    /// address -> id -> amountBurned
    mapping(address => mapping(uint256 => uint256)) private p_burnBalanceOf;
    // solhint-disable-previous-line var-name-mixedcase

    /// @dev Split contract address or any valid address to receive ethers.
    address public split;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TokenInitialized(uint256 tokenId, InitializeTokenIdParams initializeTokenIdParams);
    event NFTMinted(uint256 tokenId, uint256 amount, address beneficiary);
    event NFTBurned(uint256 tokenId, address beneficiary, uint256 amount);
    event NFTBatchMinted(uint256[] tokenIds, uint256[] amounts, address beneficiary);
    event NFTBatchBurned(address beneficiary, uint256[] tokenIds, uint256[] amounts);
    event SetSplit(address prevSplit, address newSplit);

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets `owner_` as {owner} of contract and `split_` as {split}.
    ///
    /// @param _owner addres - address of owner for contract.
    /// @param _split addres - address of split contract or any valid address.
    ///
    /// Note - `_split` address must be valid as it will receive all ethers of this contract.
    constructor(address _owner, address _split) Owned(_owner) ERC1155() {
        require(_owner != address(0), "ZERO_ADDRESS");
        require(_split != address(0), "ZERO_ADDRESS");
        split = _split;
    }

    /*//////////////////////////////////////////////////////////////
                        NON-VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a new NFT of a tokenId.
    ///
    /// @dev Add checks and inherits _mint of ERC1155 to mint new NFT of tokenId to caller.
    ///
    /// @param _id tokenId.
    /// @param _amount amount of tokenId.
    function mint(uint256 _id, uint256 _amount) external payable {
        uint256 _value = msg.value;

        require(tokenExists(_id), "INVALID_TOKENID");
        require(_value == tokenPrice(_id, _amount), "INVALID_PRICE");

        _supplyValidator(_id);
        _tokenAmountPerAccountValidator(_id, _amount);
        _timeValidator(_id);
        _ownValidator(_id);
        _burnValidator(_id);

        p_tokenInfo[_id].totalSupply += _amount;

        emit NFTMinted(_id, _amount, _msgSender());

        _mint(_msgSender(), _id, _amount, "");

        if (_value != 0) {
            Address.sendValue(payable(split), _value);
        }
    }

    /// @notice Batch mint new NFTs of tokenIds.
    ///
    /// @dev Add checks and inherits _batchMint of ERC1155 to mint new NFTs of tokenIds to caller.
    ///
    /// @param _ids tokenIds.
    /// @param _amounts amounts of tokenIds.
    function batchMint(uint256[] memory _ids, uint256[] memory _amounts) external payable {
        uint256 idsLength = _ids.length; // Saves MLOADs.
        uint256 amountsLength = _amounts.length; // Saves MLOADs.

        require(idsLength != 0 && idsLength == amountsLength, "LENGTH_MISMATCH");

        uint256 _value = msg.value;
        uint256 _totalPrice;

        uint256 _id;
        uint256 _amount;
        for (uint256 i; i < idsLength; ) {
            _id = _ids[i];
            _amount = _amounts[i];

            require(tokenExists(_id), "INVALID_TOKENID");

            _supplyValidator(_id);
            _tokenAmountPerAccountValidator(_id, _amount);
            _timeValidator(_id);
            _ownValidator(_id);
            _burnValidator(_id);

            _totalPrice += tokenPrice(_id, _amount);
            p_tokenInfo[_id].totalSupply += _amount;

            unchecked {
                ++i;
            }
        }

        require(_value == _totalPrice, "INVALID_PRICE");
        emit NFTBatchMinted(_ids, _amounts, _msgSender());

        _batchMint(_msgSender(), _ids, _amounts, "");

        if (_value != 0) {
            Address.sendValue(payable(split), _value);
        }
    }

    /// @notice Set new split contract address or any valid address to receive ethers.
    ///
    /// @param _split address - valid address to receive ethers.
    function setSplit(address _split) external onlyOwner {
        require(_split != address(0), "ZERO_ADDRESS");
        emit SetSplit(split, _split);
        split = _split;
    }

    /// @notice Owner creates new tokenId to sell NFT. If metadata is of ipfs then pattern should be "ipfs://{hash}".
    ///
    /// @dev Updates p_tokenInfo struct mapping and increments tokenId each time.
    ///
    /// @param _params InitializeTokenIdParams -
    /// _params.startTime        uint32   - startTime.
    /// _params.endTime          uint32   - endTime, 0 means it's unlimited.
    /// _params.price            uint256  - price, 0 means it's free.
    /// _params.maxSupply        uint256  - maxSupply, 0 means it's unlimited.
    /// _params.amountPerAccount uint256  - amountPerAccount, 0 means it's unlimited mints per account.
    /// _params.metadata         string   - metadata.
    /// _params.burnInfos        Burn[]   - burnInfos.
    /// _params.ownInfos         Own[]    - ownInfos.
    function initializeTokenId(InitializeTokenIdParams calldata _params) external onlyOwner {
        require(_params.startTime >= uint32(block.timestamp), "INVALID_START_TIME");
        require(bytes(_params.metadata).length > 0, "INVALID_URI");

        // incrementing tokenId
        _tokenIdTracker.increment();
        uint256 _id = _tokenIdTracker.current();

        emit TokenInitialized(_id, _params);

        p_tokenInfo[_id].exists = true;
        p_tokenInfo[_id].startTime = _params.startTime;
        p_tokenInfo[_id].metadata = _params.metadata;

        // endTime is 0 it means it's unlimited
        p_tokenInfo[_id].endTime = _params.endTime;
        // the price is 0 then means it's free
        p_tokenInfo[_id].price = _params.price;
        // maxSupply is 0 it means it's unlimited
        p_tokenInfo[_id].maxSupply = _params.maxSupply;
        // amountPerAccount is 0 it means it's unlimited mints per account
        p_tokenInfo[_id].amountPerAccount = _params.amountPerAccount;

        if (_params.burnInfos.length != 0) {
            p_tokenInfo[_id].isBurningRequired = true;

            for (uint256 i; i < _params.burnInfos.length; ) {
                p_tokenInfo[_id].burnInfos.push(_params.burnInfos[i]);

                unchecked {
                    ++i;
                }
            }
        }

        if (_params.ownInfos.length != 0) {
            p_tokenInfo[_id].isOwningRequired = true;

            for (uint256 i; i < _params.ownInfos.length; ) {
                p_tokenInfo[_id].ownInfos.push(_params.ownInfos[i]);

                unchecked {
                    ++i;
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Getter for tokenId exists.
    ///
    /// @dev Get exists flag from p_tokenInfo struct mapping.
    ///
    /// @param _id tokenId
    /// @return tokenId exists or not
    function tokenExists(uint256 _id) public view returns (bool) {
        return p_tokenInfo[_id].exists;
    }

    /// @notice Getter for price of a tokenId.
    ///
    /// @dev Gets price from p_tokenInfo struct mapping.
    ///
    /// @param _id tokenId.
    /// @return price of tokenId.
    function tokenPrice(uint256 _id, uint256 _amount) public view returns (uint256) {
        require(_amount != 0, "INVALID_AMOUNT");
        return p_tokenInfo[_id].price * _amount;
    }

    /// @notice Getter for uri metadata of a tokenId.
    ///
    /// @dev Gets uri from p_tokenInfo struct mapping.
    ///
    /// @param _id tokenId.
    /// @return uri of a tokenId.
    function uri(uint256 _id) public view virtual override returns (string memory) {
        require(tokenExists(_id), "INVALID_TOKENID");
        return p_tokenInfo[_id].metadata;
    }

    /// @notice Getter for the amount of tokens burned of token type `_id` owned by `_owner`.
    ///
    /// @param _owner address.
    /// @param _id tokenId.
    /// @return balance of `_owner`.
    function burnBalanceOf(address _owner, uint256 _id) external view returns (uint256 balance) {
        return p_burnBalanceOf[_owner][_id];
    }

    /// @notice Getter for the amounts of tokens burned of token type `ids` owned by `owners`.
    ///
    /// @param owners addresses.
    /// @param ids tokenIds.
    /// @return balances of `owners`.
    function burnBalanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i; i < owners.length; ++i) {
                balances[i] = p_burnBalanceOf[owners[i]][ids[i]];
            }
        }
    }

    /// @notice Getter for the tokenInfo of token type `_id`.
    ///
    /// @dev Gets the p_tokenInfo struct mapping.
    ///
    /// @param _id tokenId.
    function tokenInfo(uint256 _id)
        external
        view
        returns (
            bool exists,
            bool isBurningRequired,
            bool isOwningRequired,
            uint32 startTime,
            uint32 endTime,
            uint256 price,
            uint256 totalSupply,
            uint256 maxSupply,
            uint256 amountPerAccount,
            string memory metadata,
            Burn[] memory burnInfos,
            Own[] memory ownInfos
        )
    {
        TokenInfo memory _ti = p_tokenInfo[_id];

        exists = _ti.exists;
        isBurningRequired = _ti.isBurningRequired;
        isOwningRequired = _ti.isOwningRequired;
        startTime = _ti.startTime;
        endTime = _ti.endTime;
        price = _ti.price;
        totalSupply = _ti.totalSupply;
        maxSupply = _ti.maxSupply;
        amountPerAccount = _ti.amountPerAccount;
        metadata = _ti.metadata;
        burnInfos = _ti.burnInfos;
        ownInfos = _ti.ownInfos;
    }

    /// @notice returns total number of tokenIds in the token contract.
    ///
    /// @dev gets current number of tokenids from _tokenidTracker Counter library.
    ///
    /// @return number of tokenIds.
    function totalTokenIds() external view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Validates that totalSupply does not exceed maxSupply of a tokenId.
    ///
    /// @param _id tokenId.
    function _supplyValidator(uint256 _id) internal view {
        TokenInfo memory _t = p_tokenInfo[_id];
        if (_t.maxSupply > 0) {
            require(_t.totalSupply + 1 <= _t.maxSupply, "MAXSUPPLY_REACHED");
        }
    }

    /// @dev Validates that time is within start and/or end.
    ///
    /// @param _id tokenId.
    function _timeValidator(uint256 _id) internal view {
        TokenInfo memory _tokenInfo = p_tokenInfo[_id];

        require(uint32(block.timestamp) >= _tokenInfo.startTime, "MINTING_NOT_STARTED");

        // if end time is not zero it means it's limited time minting
        if (_tokenInfo.endTime != 0) {
            require(uint32(block.timestamp) < _tokenInfo.endTime, "MINTING_ENDED");
        }
    }

    /// @dev Validates that amount is less than tokenAmountPerAccount.
    ///
    /// @param _id tokenId.
    /// @param _amount amount of tokenId.
    function _tokenAmountPerAccountValidator(uint256 _id, uint256 _amount) internal view {
        uint256 _tokenAmountPerAccount = p_tokenInfo[_id].amountPerAccount;
        if (_tokenAmountPerAccount != 0) {
            require(
                _amount <= _tokenAmountPerAccount &&
                    balanceOf[_msgSender()][_id] < _tokenAmountPerAccount,
                "AMOUNT_PER_ACCOUNT_EXCEED"
            );
        }
    }

    /// @dev Validates that own info.
    ///
    /// @param _id tokenId.
    function _ownValidator(uint256 _id) internal view {
        TokenInfo memory _tokenInfo = p_tokenInfo[_id];

        // if owning is required
        if (_tokenInfo.isOwningRequired) {
            uint256 len = _tokenInfo.ownInfos.length;

            for (uint256 i; i < len; ) {
                if (_tokenInfo.ownInfos[i].nftType == NFTType.ERC721) {
                    // if ERC721, tokenId would not be used.
                    require(
                        IERC721(_tokenInfo.ownInfos[i].nftAddress).balanceOf(_msgSender()) >=
                            _tokenInfo.ownInfos[i].amount,
                        "INELIGIBLE"
                    );
                } else {
                    // if ERC1155
                    require(
                        IERC1155(_tokenInfo.ownInfos[i].nftAddress).balanceOf(
                            _msgSender(),
                            _tokenInfo.ownInfos[i].tokenId
                        ) >= _tokenInfo.ownInfos[i].amount,
                        "INELIGIBLE"
                    );
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @dev Validates that burn info.
    ///
    /// @param _id tokenId.
    ///
    // Note - if burning is required then user must give approval to this contract to allow to burn their token
    function _burnValidator(uint256 _id) internal {
        TokenInfo memory _tokenInfo = p_tokenInfo[_id];

        // if burning is required
        if (_tokenInfo.isBurningRequired) {
            require(isApprovedForAll[_msgSender()][address(this)], "NOT_AUTHORIZED");

            uint256 len = _tokenInfo.burnInfos.length;

            if (len == 1) {
                // if length is 1
                // we use burn
                Burn memory _burnInfo = _tokenInfo.burnInfos[0];
                _burnToken(_burnInfo.tokenId, _burnInfo.amount);
            } else {
                // if length is more than 1
                // we use burn batch
                uint256[] memory _ids = new uint256[](len);
                uint256[] memory _amounts = new uint256[](len);

                for (uint256 i; i < len; ) {
                    _ids[i] = _tokenInfo.burnInfos[i].tokenId;
                    _amounts[i] = _tokenInfo.burnInfos[i].amount;

                    unchecked {
                        ++i;
                    }
                }

                _batchBurnToken(_ids, _amounts);
            }
        }
    }

    /// @dev Burn a single token.
    ///
    /// @param _id tokenId.
    /// @param _amount amount.
    function _burnToken(uint256 _id, uint256 _amount) internal {
        require(tokenExists(_id), "INVALID_TOKENID");

        // update state
        p_burnBalanceOf[_msgSender()][_id] += _amount;

        p_tokenInfo[_id].totalSupply -= _amount;
        // should maxSupply be reduced?

        emit NFTBurned(_id, _msgSender(), _amount);


        _burn(_msgSender(), _id, _amount);
    }

    /// @dev Burn multiple tokens.
    ///
    /// @param _ids tokenIds.
    /// @param _amounts amounts.
    function _batchBurnToken(uint256[] memory _ids, uint256[] memory _amounts) internal {
        uint256 idsLength = _ids.length;

        uint256 _id;
        uint256 _amount;
        for (uint256 i; i < idsLength; ) {
            _id = _ids[i];
            _amount = _amounts[i];

            require(tokenExists(_id), "INVALID_TOKENID");

            // update state
            p_burnBalanceOf[_msgSender()][_id] += _amount;
            p_tokenInfo[_id].totalSupply -= _amount;




            unchecked {
                ++i;
            }
        }

        emit NFTBatchBurned(_msgSender(), _ids, _amounts);

        _batchBurn(_msgSender(), _ids, _amounts);
    }
}