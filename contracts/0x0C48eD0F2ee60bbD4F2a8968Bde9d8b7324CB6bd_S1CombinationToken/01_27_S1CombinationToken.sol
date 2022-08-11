pragma solidity ^0.8.6;

import "./library/Basis.sol";
import "./interfaces/IBaseToken.sol";
import "./interfaces/ICombinationToken.sol";
import "./library/Withdrawable.sol";

contract S1CombinationToken is ICombinationToken, Basis {
    using ECDSA for bytes32;

    // <VARIABLES>
    bool public isInitialized = false;
    mapping(uint256 => bool) public paidOut;
    bool public paidOutIterable;
    uint256 public mintStartTime;

    // Parental base token contract
    IBaseToken internal parent_;
    // Parents for each token by it's ID
    mapping(uint256 => uint256[]) internal tokenParents_;
    // Name for each of every collection
    mapping(uint256 => string) internal combinationName_;
    // A map to store if token is combined
    mapping(uint256 => bool) internal baseIsCombined_;
    // A map to store child to parent mapping
    mapping(uint256 => uint256) internal childByParent_;
    // Max total supply and last token ID
    uint256 public maxTotalSupply = 203;

    /*
    @notion REWARD POOL
            Array which stores a reward for each winner
    */
    uint256[] public rewards;
    // </ VARIABLES>

    // <EVENTS>
    event MintCombinationToken(
        uint256 tokenId,
        address to,
        uint256[] parents
    );

    event RewardPayout(address claimer, uint256 amount, uint256 tokenId);
    event RewardPayoutDone();

    // onlyOwner events
    event Initialize();
    event SetRewards();
    event SetMaxTotalSupply(uint256 newMaxTotalSupply);
    event SetMintStartTime(uint256 mintStartTime);

    // </ EVENTS>

    /**
        @notice A constructor function is executed once when a contract is created and it is used to initialize
                contract state.
        @param _proxyRegistry - wyvern proxy for secondary sales on Opensea (cannot be changed after)
        @param _name - combination token name (cannot be changed after)
        @param _symbol - combination token symbol (cannot be changed after)
        @param _baseURI - combination token address where NFT images are stored
        @param _contractURI - combination token contract metadata URI
        @param _parent - parental BaseToken contract address
        @param _paymentToken - Wrapped ETH (WETH) token contract address for secondary sales (cannot be changed after)
    */
    constructor(
        address _proxyRegistry,
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _contractURI,
        address _parent,
        address _paymentToken
    )
    Basis(
        _proxyRegistry,
        _name,
        _symbol,
        _baseURI,
        _contractURI,
        _paymentToken
    )
    {
        parent_ = IBaseToken(_parent);
    }

    // <PUBLIC FUNCTIONS>

    function initialize(
        uint256[] memory _rewards
    ) external virtual onlyOwner {
        require(!isInitialized, "S1CombinationToken: contract is already initialized!");
        isInitialized = true;

        rewards = _rewards;

        emit Initialize();
    }

    /*
        @notion Public function called by user (Base tokens holder) to create a combination token
        @dev Function calls validateCombination in BaseToken.sol smart contract for Combination
             NFT validation
        @param _parents - array of Base token IDs 4 Base NFT from which Combination NFT should be minted
        @param _name - name of Combination NFT
    **/
    function mintCombinationToken(
        uint256[] memory _parents,
        string memory _name
    ) external virtual returns (uint256 _tokenId) {
        address _msgSender = msg.sender;
        _tokenId = lastTokenId_ + 1;

        require(_tokenId <= _maxTotalSupply(), "S1CombinationToken: total supply limit");
        require(mintStartTime != 0 && mintStartTime < block.timestamp, "S1CombinationToken: combination minting is not started yet");

        require(
            _parents.length == 4,
            "S1CombinationToken: invalid parents amount"
        );

        if (_tokenId == 1) {
            require(parent_.soldOut(), "S1CombinationToken: base tokens are not sold out yet");
        }

        // get token ID
        lastTokenId_++;

        _validateCombination(
            _parents,
            _msgSender,
            _tokenId
        );

        // set combination name
        combinationName_[_tokenId] = _name;
        // set token's parents
        tokenParents_[_tokenId] = _parents;
        // mint token
        _mint(_msgSender, _tokenId);

        emit MintCombinationToken(_tokenId, _msgSender, _parents);

        return _tokenId;
    }


    /**
        @dev A simple getter of a parental BaseToken contract
    */
    function parent() external view override returns (IBaseToken) {
        return parent_;
    }

    /**
        @dev Get a base tokens used to combine combination
        @param _tokenId - Combination token Id
        @return uint256[] - an array of Base tokens
    */
    function tokenParents(uint256 _tokenId)
    external
    view
    override
    returns (uint256[] memory)
    {
        return tokenParents_[_tokenId];
    }

    /**
        @dev Returns true if base token is already used
        @param _baseId - Base token Id
        @return bool - true if token is combined and
                false if it's not
    */
    function baseIsCombined(uint256 _baseId)
    external
    view
    override
    returns (bool)
    {
        return baseIsCombined_[_baseId];
    }

    /**
        @dev Returns Combination token name
        @param _tokenId - Combination token Id
        @return string - Token name set by user
    */
    function combinationName(uint256 _tokenId)
    external
    view
    override
    returns (string memory)
    {
        return combinationName_[_tokenId];
    }

    /**
        @dev Get a combination token child by it's parental base token Id
        @param _baseId - Base token Id
        @return uint256 - Combination token Id
    */
    function childByParent(uint256 _baseId)
    external
    view
    override
    returns (uint256)
    {
        return childByParent_[_baseId];
    }

    function payoutReward() external virtual {
        uint256[] memory _rewards = rewards;
        require(!paidOutIterable, "S1CombinationToken: reward is already paid out");
        paidOutIterable = true;
        require(lastTokenId_ >= _rewards.length, "S1CombinationToken: not enough combinations are minted yet");

        uint256 _len = _rewards.length;

        for (
            uint256 index = 0;
            index < _len;
            index++
        ) {
            uint256 _tokenId = index + 1;
            uint256 _payoutAmount = _rewards[index];
            address _tokenOwner = ownerOf(_tokenId);
            if (!_isContract(_tokenOwner)) {
                payable(_tokenOwner).transfer(_payoutAmount);
                paidOut[_tokenId] = true;

                emit RewardPayout(_tokenOwner, _payoutAmount, _tokenId);
            }
        }

        emit RewardPayoutDone();
    }

    function getMyReward(uint256 _tokenId) external virtual {
        require(paidOutIterable, "S1CombinationToken: all rewards are not paid out yet");
        require(!paidOut[_tokenId], "S1CombinationToken: reward by this token is already paid out");
        address _txSender = msg.sender;
        require(ownerOf(_tokenId) == _txSender, "S1CombinationToken: Looks like it's not your token");
        paidOut[_tokenId] = true;

        uint256 _payoutAmount = rewards[_tokenId];

        payable(_txSender).transfer(_payoutAmount);

        emit RewardPayout(_txSender, _payoutAmount, _tokenId);
    }

    function setRewards(
        uint256[] memory _rewards
    ) external virtual onlyOwner {
        rewards = _rewards;

        emit SetRewards();
    }

    function setMaxTotalSupply(uint256 _newMaxTotalSupply) external onlyOwner {
        maxTotalSupply = _newMaxTotalSupply;

        emit SetMaxTotalSupply(_newMaxTotalSupply);
    }

    function setMintStartTime(uint256 _newMintStartTime) external onlyOwner {
        mintStartTime = _newMintStartTime;

        emit SetMintStartTime(_newMintStartTime);
    }

    /**
        @notice A function to serve constant maxTotalSupply
        @dev Function was created for dev purposes, to make proper testing simpler
        @return constant maxTotalSupply variable
    */
    function _maxTotalSupply() internal view virtual returns (uint256) {
        return maxTotalSupply;
    }

    function _validateCombination(
        uint256[] memory _parents,
        address _msgSender,
        uint256 _childId
    ) internal {
        (uint8 _firstMaterial, uint8 _firstEdging, uint8 _firstSuit, uint16 _firstRank) = parent_.baseTokenMainTraits(_parents[0]);
        bytes32 _expectedTraitsHash = keccak256(
            abi.encodePacked(
                _firstMaterial,
                _firstEdging,
                _firstRank
            )
        );

        uint16 _suitChecksum = _firstSuit;
        require(
            parent_.ownerOf(_parents[0]) == _msgSender,
            "S1CombinationToken: you are not a token owner"
        );
        require(
            childByParent_[_parents[0]] == 0,
            "S1CombinationToken: parent already has a child"
        );
        childByParent_[_parents[0]] = _childId;
        baseIsCombined_[_parents[0]] = true;

        for (uint256 i = 1;
            i < _parents.length;
            i++) {
            uint256 _currentlyIterableToken = _parents[i];
            require(
                parent_.ownerOf(_currentlyIterableToken) == _msgSender,
                "S1CombinationToken: you are not a token owner"
            );
            require(
                childByParent_[_currentlyIterableToken] == 0,
                "S1CombinationToken: parent already has a child"
            );

            (uint8 _currentMaterial, uint8 _currentEdging, uint8 _currentSuit, uint16 _currentRank) = parent_.baseTokenMainTraits(_currentlyIterableToken);

            require(_expectedTraitsHash == keccak256(
                abi.encodePacked(
                    _currentMaterial,
                    _currentEdging,
                    _currentRank
                )
            ),
                "S1CombinationToken: wrong material/edging/rank"
            );
            _suitChecksum += _currentSuit;
            childByParent_[_currentlyIterableToken] = _childId;
            baseIsCombined_[_currentlyIterableToken] = true;
        }

        require(_suitChecksum == 15, "S1CombinationToken: wrong suits");
    }

    /**
        @notice Used to receive Ether from Base Token contract
        @dev Function is executed if none of the other functions match the function
             identifier or no data was provided with the function call
    */
    fallback() external payable {}

    /**
        @notice Used to receive Ether from Base Token contract
        @dev Function is executed if none of the other functions match the function
             identifier or no data was provided with the function call
    */
    receive() external payable {}

    /**
        @notice Used to protect Owner from shooting himself in a foot
        @dev This function overrides same-named function from Ownable
             library and makes it an empty one
    */
    function renounceOwnership() public override onlyOwner {}
}