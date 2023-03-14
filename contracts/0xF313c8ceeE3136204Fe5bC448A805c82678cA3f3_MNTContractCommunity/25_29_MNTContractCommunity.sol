pragma solidity ^0.8.13;

import "./MNTContract.sol";

/// @author Monumental Team
/// @title Community Contract
contract MNTContractCommunity is MNTContract {

    uint256 private _basisPrice;
    uint256 private _currentOwnerBalance;
    uint256 private _maxMintAmount;
    uint256 private _nftPerAddressLimit;
    bool private _onlyWhitelisted;
    address[] private _whitelistedAddresses;
    address[] private  _feeRecipients;
    uint32[] private _feePercentages;

    mapping(address => uint256) private addressMintedBalance;

    uint32 private constant gasLimit = 100000;

    event MNTPaymentDetail(address from, address to, uint256 _amount, bool success);

    event MNTPaymentGlobal(address from, address to, uint256 _sumBasisPrice, uint256 sumFees, uint256 _royalties);

    struct CommunityEditionInfo {
        uint256 _balance;
        uint256 _basisPrice;
        uint256 _maxMintAmount;
        uint256 _nftPerAddressLimit;
        uint256 _mintedAmount;
        bool    _onlyWhitelisted;
        bool    _isWhitelisted;
    }

    modifier isFeePercentagesLessThanMaximum(uint32[] memory _feePercentages) {
        uint32 totalPercent;
        for (uint256 i = 0; i < _feePercentages.length; i++) {
            totalPercent = totalPercent + _feePercentages[i];
        }
        require(totalPercent <= 10000, "Fee percentages exceed maximum");
        _;
    }

    modifier correctFeeRecipientsAndPercentages(
        uint256 _recipientsLength,
        uint256 _percentagesLength
    ) {
        require(_recipientsLength == _percentagesLength, "Recipients != percentages");
        _;
    }

    /// Community constructor
    /// @param stringOptions contract name
    /// @param creator creator address
    /// @param royalties royalties
    /// @param maxSupply max supply
    /// @param communityOptions community options
    /// @param onlyWhitelisted restricted presale if set, otherwise public sale
    /// @param wlAddresses whitelist eth addresses
    /// @param feeRecipients recipient fees
    /// @param feePercentages percentages fees
    /// @notice Community constructor
    function initializeCommunity(
        string[] memory stringOptions,
        address creator,
        uint256 royalties,
        uint256 maxSupply,
        uint256[] memory communityOptions,
        bool onlyWhitelisted,
        address[] memory wlAddresses,
        address[] memory feeRecipients,
        uint32[] memory feePercentages
    ) public override
    correctFeeRecipientsAndPercentages(feeRecipients.length, feePercentages.length)
    isFeePercentagesLessThanMaximum(feePercentages)
    returns (bool)
    {

        super.initializeCommunity(stringOptions, creator, royalties, maxSupply, communityOptions, onlyWhitelisted, wlAddresses, feeRecipients, feePercentages);

        _basisPrice = communityOptions[0];
        _currentOwnerBalance = 0;
        _maxMintAmount = communityOptions[1];
        _nftPerAddressLimit = communityOptions[2];
        _whitelistedAddresses = wlAddresses;
        _feeRecipients = feeRecipients;
        _feePercentages = feePercentages;

        setOnlyWhitelisted(onlyWhitelisted);

        transferOwnership(creator);
        return true;
    }

    /// Mint a community contract
    /// @param _mintAmount _mintAmount
    /// @param _pinCode _pinCode
    /// @notice Mint a community contract
    function mintCommunity(uint256 _mintAmount, uint256 _pinCode) public nonReentrant payable {
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_mintAmount <= _maxMintAmount, "max mint amount per session exceeded");
        uint256 supply = super.getCurrentTokenId();
        require(supply + _mintAmount  <= maxSupply() - getTokenBurntId(), "max NFT limit exceeded");

        if (msg.sender != owner()) {
            if (_onlyWhitelisted == true) {
                require(isWhitelisted(msg.sender), "user is not whitelisted");
                uint256 ownerMintedCount = addressMintedBalance[msg.sender];
                require(ownerMintedCount + _mintAmount <= _nftPerAddressLimit, "max NFT per address exceeded");
            }
            require(msg.value >= _basisPrice * _mintAmount, "insufficient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            super.incrementTokenId();
            uint256 newItemId = super.getCurrentTokenId();
            addressMintedBalance[msg.sender]++;

            uint256 _tokenId = supply + i;
            super._safeMint(_creator, _tokenId);

            // Make a transfer for consistency on blockchain
            // (ie : second market instead of primary one)
            if(_creator != msg.sender) {
                super._setApprovalForAll(_creator, msg.sender, true);
                super.transferFrom(_creator, msg.sender, _tokenId);
            }
            else {
                // For creator, the balance is saved for withdraw purpose
                _currentOwnerBalance = _currentOwnerBalance + _basisPrice;
            }

            emit MNTMintDone(msg.sender, _pinCode, newItemId);
        }
    }

    /// Override of the beforeTokenTransfer (emitting an event)
    /// @param from from
    /// @param to to
    /// @param tokenId tokenId
    /// @param batchSize batchSize
    /// @notice Ensure that during presale, no transfer is allowed unless its a new mint or a transfer to the minter
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    whenNotPaused
    override(ERC721Upgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // We ensure that during presale, no transfer is allowed
        // unless its a new mint or a transfer to the minter
        require(!_onlyWhitelisted || from == address(0) || from == _creator, "token transfer while ongoing presale");
    }

    /// Check if a user is whitelisted
    /// @param _user user to check
    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < _whitelistedAddresses.length; i++) {
            if (_whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    /// Get the current mint balance for a user
    /// @param _user user
    function getMintedBalance(address _user) public view returns (uint256) {
        return addressMintedBalance[_user];
    }

    /// Set nft per address limit
    /// @param limit nft per address limit
    function setNftPerAddressLimit(uint256 limit) public onlyOwner {
        _nftPerAddressLimit = limit;
    }

    /// Set basis price
    /// @param newBasisPrice new basis price
    function setBasisPrice(uint256 newBasisPrice) public onlyOwner {
        _basisPrice = newBasisPrice;
    }

    /// Set max mint amount
    /// @param newMaxMintAmount new max mint amount
    function setMaxMintAmount(uint256 newMaxMintAmount) public onlyOwner {
        _maxMintAmount = newMaxMintAmount;
    }

    /// Set only whiteListed
    /// @param state true/false
    /// @notice if true, only presale. Otherwise, public sale
    function setOnlyWhitelisted(bool state) public onlyOwner {
        _onlyWhitelisted = state;
    }

    /// Define a white list users
    /// @param users user list
    /// @notice Allow to define a list of users
    function whitelistUsers(address[] calldata users) public onlyOwner {
        delete _whitelistedAddresses;
        _whitelistedAddresses = users;
    }

    /// Depending on a percentage, return the corresponding price
    /// @param inputPrice input price
    /// @param percentage percentage of the basis price
    /// @notice Compute a price depending on a given percentage
    function _computePercentagePrice(uint256 inputPrice, uint256 percentage)
    internal
    pure
    returns (uint256)
    {
        return (inputPrice * (percentage)) / 10000;
    }

    /// Send funds to recipient
    /// @param _recipient recipient address
    /// @param _amount amount
    /// @notice Send funds to recipient
    function _payout(
        address _recipient,
        uint256 _amount
    ) internal
    returns (bool)
    {
        (bool success,) = payable(_recipient).call{value : _amount, gas : gasLimit}("");
        return success;
    }

    /// Withdraw the contract balance
    /// Balance increase after each mint
    /// @notice Withdraw the contract balance
    function withdraw() public payable onlyOwner {

        uint256 feesPaid;
        uint256 sumBasisPrice = address(this).balance;

        // We count how many tokens the owner has in his wallet
        uint256 totalPrice  = sumBasisPrice - _currentOwnerBalance;

        // Pay platform fees
        for (uint256 i = 0; i < _feeRecipients.length; i++) {
            uint256 fee = _computePercentagePrice(totalPrice, _feePercentages[i]);
            feesPaid = feesPaid + fee;
            bool success = _payout(_feeRecipients[i], fee);
            emit MNTPaymentDetail(address(this), _feeRecipients[i], fee, success);
        }

        // Pay the rest to the owner
        uint256 rest = address(this).balance;
        bool success = _payout(owner(), rest);
        if(success) {
            _currentOwnerBalance = 0;
        }
        emit MNTPaymentDetail(address(this), owner(), rest, success);

        emit MNTPaymentGlobal(address(this), owner(), totalPrice, feesPaid, _royalties);

    }

    /// Overview of the community edition contract state for given user
    /// @param userAddress user
    /// @notice Return an overview of the community edition contract state
    function getCommunityEditionInfo(address userAddress) public view returns (CommunityEditionInfo memory){

        CommunityEditionInfo memory info = CommunityEditionInfo(
        address(this).balance,
        _basisPrice,
        _maxMintAmount,
        _nftPerAddressLimit,
        addressMintedBalance[userAddress],
        _onlyWhitelisted,
        isWhitelisted(userAddress)
        );

        return info;
    }

}