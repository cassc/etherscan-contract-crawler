//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

/// @title Anime Metaverse Ticket Smart Contract
/// @author LiquidX
/// @notice This contract is used to mint free ticket and premium ticket

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAnimeMetaverseTicket.sol";
import "./AmvUtils.sol";

/// @notice Thrown when free ticket it's not able to be minted
error FreeTicketMintingNotActive();
/// @notice Thrown when invalid destination address specified (address(0) or address(this))
error InvalidAddress();
/// @notice Thrown when burning less than 1 ticket
error InvalidBurnAmount();
/// @notice Thrown when max supply is less than total supply
error InvalidMaxSupply();
/// @notice Thrown when current token ID is already used by other token
error InvalidTokenId();
/// @notice Thrown when minting ticket more than its limit
error MaximumLimitToMintTicketExceeded();
/// @notice Thrown when the address is not allowed/exist in the burner list
error NotAllowedToBurn();
/// @notice Thrown when premium ticket it's not able to be minted
error PremiumTicketMintingNotActive();
/// @notice Thrown when inputting 0 as value
error ValueCanNotBeZero();
/// @notice Thrown when the length of array does not match with other array
error InvalidArrayLength();
/// @notice Thrown when an address is already whitelisted
error AlreadyWhiteListed(address wlAddress);
/// @notice Thrown when an address is not whitelisted
error NotWhiteListed(address wlAddress);

contract AnimeMetaverseTicket is
    Ownable,
    ERC1155,
    AmvUtils,
    IAnimeMetaverseTicket
{
    /// @dev Address who can withdraw the balance
    address payable withdrawalWallet;

    uint256 constant FREE_TICKET_TOKEN_ID = 1;
    uint256 constant PREMIUM_TICKET_TOKEN_ID = 2;
    /// @notice Initial premium ticket price when the contract was deployed
    uint256 public constant DEFAULT_PREMIUM_TICKET_PRICE = 0.06 ether;

    /// @dev State that decides whether user can mint free ticket or not
    bool public freeTicketMintingActive = false;
    /// @dev State that decides whether user can mint premium ticket or not
    bool public premiumTicketMintingActive = false;

    /// @notice Maximum free ticket supply
    /// @dev The maximum limit should not be less than total supply
    uint256 public freeTicketMaxSupply = 16000;
    /// @notice Maximum premium ticket supply
    /// @dev The maximum limit should not be less than total supply
    uint256 public premiumTicketMaxSupply = 20000;

    /// @notice Total free ticket that has been minted
    /// @dev The number will increase everytime there is a mint transaction
    uint256 public freeTicketTotalSupply = 0;
    /// @notice Total premium ticket that has been minted
    /// @dev The number will increase everytime there is a mint transaction
    uint256 public premiumTicketTotalSupply = 0;

    /// @notice Maximum limit for minting premium ticket in one transaction
    uint256 public maxPremiumTicketMintLimit = 100;

    /// @notice Current premium ticket price
    /// @dev This variable value can change since it's
    ///      storing the default price only for the first time
    uint256 public premiumTicketPrice = DEFAULT_PREMIUM_TICKET_PRICE;

    /// @notice Storing base URL for ticket metadata
    string public baseURI = "";

    /// @notice Store detail information related to whitelisted address
    /// @dev Whitelisted user are those who can mint free ticket
    /// @param maxAllowedToMint maximum free ticket user can mint
    /// @param alreadyMinted amount of free ticket that is already minted by user
    struct WhiteListedUser {
        uint256 maxAllowedToMint;
        uint256 alreadyMinted;
    }

    /// @notice List of whitelisted address and their eligible free ticket amount
    /// @dev Every address will contain information in the WhiteListedUser struct
    mapping(address => WhiteListedUser) public whiteListedUsersInfo;
    /// @notice List of address who's allowed to burn the ticket
    /// @dev The burner address list can only be set by the contract owner
    ///      and the value will be boolean. 'true' means allowed, otherwise
    ///      it's not.
    mapping(address => bool) public burnerList;

    /// @notice Check whether the address is a wallet address
    /// @dev Check if address is not 0x0 or contract address
    /// @param _address Any valid ethereum address
    modifier validAddress(address _address) {
        if (_address == address(0) || _address == address(this)) {
            revert InvalidAddress();
        }
        _;
    }

    /// @notice Check whether current token ID is either free ticket or premium ticket ID
    /// @param _tokenId Any unsigned integer number
    modifier validTokenId(uint256 _tokenId) {
        if (
            _tokenId != FREE_TICKET_TOKEN_ID &&
            _tokenId != PREMIUM_TICKET_TOKEN_ID
        ) {
            revert InvalidTokenId();
        }
        _;
    }

    /// @notice Check whether the length of 2 lists are same.
    /// @dev Check whether the length of 2 arrays of unsigned integer are same.
    /// @param _length1 First array
    /// @param _length2 Second array
    modifier validInputArrayLength(uint256 _length1, uint256 _length2) {
        if (_length1 != _length2) {
            revert InvalidArrayLength();
        }
        _;
    }

    /// @notice Check whether the input is zero
    /// @param amount Any unsigned integer number
    modifier NotZero(uint256 amount) {
        if (amount == 0) {
            revert ValueCanNotBeZero();
        }
        _;
    }

    /// @notice Whether there is a mint transaction for free ticket
    /// @dev This event can also be used to audit the total supply of free ticket
    /// @param _receiver Address who mint the ticket
    /// @param _mintAmount How many ticket is minted in the transaction
    /// @param _tokenId The ticket token ID
    event MintFreeTicket(
        address _receiver,
        uint256 _mintAmount,
        uint256 _tokenId
    );
    /// @notice Whether there is a mint transaction for premium ticket
    /// @dev This event can also be used to audit the total supply of premium ticket
    /// @param _receiver Address who mint the ticket
    /// @param _mintAmount How many ticket is minted in the transaction
    /// @param _tokenId The ticket token ID
    event MintPremiumTicket(
        address _receiver,
        uint256 _mintAmount,
        uint256 _tokenId
    );
    /// @notice Emit whenever a ticket is burned
    /// @dev This event can also be used to audit the total of burned ticket
    /// @param _ticketOwner Owner of the ticket
    /// @param _burnAmount How many ticket is burned
    /// @param _tokenId The ticket token ID
    event BurnTicket(
        address _ticketOwner,
        uint256 _burnAmount,
        uint256 _tokenId
    );

    /// @notice Set initial address who can withdraw the balance in this contract
    /// @dev The ERC1155 function is derived from Open Zeppelin ERC1155 library
    constructor() ERC1155("") {
        withdrawalWallet = payable(msg.sender);
    }

    /// @notice Add address to whitelist and set their free ticket quota
    /// @param _accounts list of address that will be added to whitelist
    /// @param _ticketAmounts amount of free ticket each user can mint
    function addToWhitelistBatch(
        address[] memory _accounts,
        uint256[] memory _ticketAmounts
    )
        public
        onlyOwner
        validInputArrayLength(_accounts.length, _ticketAmounts.length)
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            if (_accounts[i] == address(0) || _accounts[i] == address(this)) {
                revert InvalidAddress();
            }
            if (whiteListedUsersInfo[_accounts[i]].maxAllowedToMint != 0) {
                revert AlreadyWhiteListed(_accounts[i]);
            }
            if (_ticketAmounts[i] < 1) {
                revert ValueCanNotBeZero();
            }
            whiteListedUsersInfo[_accounts[i]] = WhiteListedUser({
                maxAllowedToMint: _ticketAmounts[i],
                alreadyMinted: 0
            });
        }
    }
    
    /// @notice updates whitelistedusers for free minting
    /// @dev This function can be used to override maximum quota of
    ///      the free ticket that user can mint
    /// @param _accounts list of address that will be updated
    /// @param _ticketAmounts amount of free ticket each user can mint
    function updateWhitelistBatch(
        address[] memory _accounts,
        uint256[] memory _ticketAmounts
    )
        public
        onlyOwner
        validInputArrayLength(_accounts.length, _ticketAmounts.length)
    {
        for (uint256 i = 0; i < _accounts.length; i++) {
            if (_accounts[i] == address(0) || _accounts[i] == address(this)) {
                revert InvalidAddress();
            }
            if (whiteListedUsersInfo[_accounts[i]].maxAllowedToMint == 0) {
                revert NotWhiteListed(_accounts[i]);
            }
            require(
                _ticketAmounts[i] >=
                    whiteListedUsersInfo[_accounts[i]].alreadyMinted,
                "max allowed to mint ticket needs to be greate or equal than already minted ticket for this address."
            );
            whiteListedUsersInfo[_accounts[i]]
                .maxAllowedToMint = _ticketAmounts[i];
        }
    }

    /// @notice Mint free ticket that only available for whitelisted address
    /// @dev Use _mint method from ERC1155 function which derived from Open Zeppelin ERC1155 library. It will increase alreadyMinted value based on amount of minted ticket
    /// @param _mintAmount How many free ticket to mint
    function mintFreeTicket(uint256 _mintAmount) external NotZero(_mintAmount) {
        if (!freeTicketMintingActive) {
            revert FreeTicketMintingNotActive();
        }
        require(
            freeTicketTotalSupply + _mintAmount <= freeTicketMaxSupply,
            "Total minted Ticket count has reached the mint limit."
        );

        require(
            IsMintRequestValid(msg.sender, _mintAmount),
            "you are not whitelisted or already exceeded maximum limit to mint Free Ticket."
        );
        freeTicketTotalSupply += _mintAmount;
        whiteListedUsersInfo[msg.sender].alreadyMinted += _mintAmount;
        _mint(msg.sender, FREE_TICKET_TOKEN_ID, _mintAmount, "");
        emit MintFreeTicket(msg.sender, _mintAmount, FREE_TICKET_TOKEN_ID);
    }

    /// @notice Mint permium ticket that available for any address
    /// @dev Whitelisted address can also mint premium ticket and doesn't
    ///      increase the alreadyMinted value
    /// @param _mintAmount How many premium ticket to mint
    function mintPremiumTicket(uint256 _mintAmount)
        external
        payable
        NotZero(_mintAmount)
    {
        if (!premiumTicketMintingActive) {
            revert PremiumTicketMintingNotActive();
        }
        if (_mintAmount > maxPremiumTicketMintLimit) {
            revert MaximumLimitToMintTicketExceeded();
        }
        require(
            msg.value == premiumTicketPrice * _mintAmount,
            "insufficient or excess ETH provided."
        );
        require(
            premiumTicketTotalSupply + _mintAmount <= premiumTicketMaxSupply,
            "Total minted Ticket count has reached the mint limit."
        );
        premiumTicketTotalSupply += _mintAmount;
        _mint(msg.sender, PREMIUM_TICKET_TOKEN_ID, _mintAmount, "");
        emit MintPremiumTicket(
            msg.sender,
            _mintAmount,
            PREMIUM_TICKET_TOKEN_ID
        );
    }

    /// @notice this is an owner function which airdrops permium tickets
    /// @param _addresses these will get airdropped premium tickets.
    /// @param _amounts number of premium tickets to be airdropped.
    function airDropPremiumTicket(
        address[] memory _addresses,
        uint256[] memory _amounts
    )
        external
        onlyOwner
        validInputArrayLength(_addresses.length, _amounts.length)
    {
        uint256 amount = 0;
        for (uint256 i = 0; i < _addresses.length; i++) {
            amount += _amounts[i];
        }
        require(
            premiumTicketTotalSupply + amount <= premiumTicketMaxSupply,
            "Total minted Ticket count has reached the mint limit."
        );
        premiumTicketTotalSupply += amount;
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], PREMIUM_TICKET_TOKEN_ID, _amounts[i], "");
        }
        
    }

    /// @notice Check whether the whitelisted address still eligible to
    ///         mint free ticket
    /// @dev It will calculate the alreadyMinted value + the _mintAmount
    ///      and the value should be less than equal to maxAllowedToMint
    /// @param _walletAddress Any valid wallet address
    /// @param _mintAmount How many free tickets to mint
    function IsMintRequestValid(address _walletAddress, uint256 _mintAmount)
        public
        view
        returns (bool)
    {
        if (
            whiteListedUsersInfo[_walletAddress].alreadyMinted + _mintAmount <=
            whiteListedUsersInfo[_walletAddress].maxAllowedToMint
        ) return true;
        else return false;
    }

    /// @notice Burn ticket
    /// @dev It will use _burn method from Open Zeppelin ERC1155 library
    /// @param tokenId Ticket token ID
    /// @param _account Address who burn the ticket
    /// @param _numberofTickets How many tickets to burn
    function burn(
        uint256 tokenId,
        address _account,
        uint256 _numberofTickets
    ) public validTokenId(tokenId) {
        if (!burnerList[msg.sender]) {
            revert NotAllowedToBurn();
        }
        if (_numberofTickets < 1) {
            revert InvalidBurnAmount();
        }
        _burn(_account, tokenId, _numberofTickets);
        emit BurnTicket(_account, _numberofTickets, tokenId);
    }

    /// @notice Update max supply for premium ticket
    /// @dev Max supply should not be less than the premium ticket total supply
    /// @param _newMaxSupply New maximum supply for premium ticket
    function updateMaxSupplyForPremiumTicket(uint256 _newMaxSupply)
        external
        onlyOwner
    {
        if (_newMaxSupply < premiumTicketTotalSupply) {
            revert InvalidMaxSupply();
        }
        premiumTicketMaxSupply = _newMaxSupply;
    }

    /// @notice Update max supply for free ticket
    /// @dev Max supply should not be less than the free ticket total supply
    /// @param _newMaxSupply New maximum supply for free ticket
    function updateMaxSupplyForFreeTicket(uint256 _newMaxSupply)
        external
        onlyOwner
    {
        if (_newMaxSupply < freeTicketTotalSupply) {
            revert InvalidMaxSupply();
        }
        freeTicketMaxSupply = _newMaxSupply;
    }

    /// @notice Set wallet address that can withdraw the balance
    /// @dev Only owner of the contract can execute this function.
    ///      The address should not be 0x0 or contract address
    /// @param _wallet Any valid address
    function setWithdrawWallet(address _wallet)
        external
        onlyOwner
        validAddress(_wallet)
    {
        withdrawalWallet = payable(_wallet);
    }

    /// @notice Set address that can burn ticket
    /// @dev Only owner of the contract can execute this function.
    ///      The address should not be 0x0 or contract address
    /// @param _burner The address that will be registered in burner list
    /// @param _flag Whether the address can burn the ticket or not
    function setBurnerAddress(address _burner, bool _flag)
        external
        onlyOwner
        validAddress(_burner)
    {
        burnerList[_burner] = _flag;
    }

    /// @notice Transfer balance on this contract to withdrawal address
    function withdrawETH() external onlyOwner {
        withdrawalWallet.transfer(address(this).balance);
    }

    /// @notice Update premium ticket price
    function updateMintPrice(uint256 _newPrice) external onlyOwner {
        premiumTicketPrice = _newPrice;
    }

    /// @notice Reset premium ticket price to default price
    /// @dev The default price is the value of DEFAULT_PREMIUM_TICKET_PRICE variable
    function resetMintPrice() external onlyOwner {
        premiumTicketPrice = DEFAULT_PREMIUM_TICKET_PRICE;
    }

    /// @notice Set base URL for metadata
    /// @param _newuri URL for metadata
    function setURI(string memory _newuri) public onlyOwner {
        baseURI = _newuri;
    }

    /// @notice Set maximum limit for minting premium ticket in one transaction
    /// @dev The limit should not be more than the difference of maximum
    ///      premium ticket supply and premium ticket total supply
    /// @param _maxLimit New maximum limit for minting premium ticket
    function updateMaxMintLimitForPremiumTicket(uint256 _maxLimit)
        external
        onlyOwner
        NotZero(_maxLimit)
    {
        if (_maxLimit > (premiumTicketMaxSupply - premiumTicketTotalSupply)) {
            revert();
        }
        maxPremiumTicketMintLimit = _maxLimit;
    }

    /// @notice Activate free ticket mint functionality
    /// @dev This will either prevent/allow minting transaction in this contract
    /// @param _flag Whether to enable or disable the minting functionality
    function ActivateFreeTicketMinting(bool _flag) external onlyOwner {
        freeTicketMintingActive = _flag;
    }

    /// @notice Activate premium ticket mint functionality
    /// @dev This will either prevent/allow minting transaction in this contract
    /// @param _flag Whether to enable or disable the minting functionality
    function ActivatePremiumTicketMinting(bool _flag) external onlyOwner {
        premiumTicketMintingActive = _flag;
    }

    /// @notice Append token ID to base URL
    /// @param _tokenId Ticket token ID
    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, intToString(_tokenId)))
                : "";
    }
}