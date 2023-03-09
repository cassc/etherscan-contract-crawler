// SPDX-License-Identifier: MIT

/*
                                                                         
                             .:-=+**###%###*++===-:.                            
                        .-=++=--:........:--=+**+-.:=====-.                     
                      -+- .:-----=+++++:        .=+:     .-===.                 
                    .+:   [email protected]@*******#@@+           :=.        -++:              
                   -=     [email protected]@. :--. [email protected]@+             -:          :=-            
                  -=      [email protected]@: =##**#@@+  ....        -:           .+-          
                 :=       [email protected]@***++. [email protected]@%#%####%%*-     =.            =+         
                 +        *@@:.===. [email protected]@*        :+%.    *             *-        
                -:        *@@%%%####%@@-                .-             *        
                +. .......-=====+*+====.                 -             +        
   :+*#%%###*+++++===---------======++*+======++===--::...-            =.       
   *#+===+++**++##%%%%%%%%%%%%###*#*++===--------:--:--=+#@@@%%%##*=-:.-+       
                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#       
                @@@@@@@%@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%       
                [email protected]@@@@@*#@@@@@@@=*@@@@@%[email protected]@@@@*@@@@@#*@@@@@@@@@@@@@@@@@@%       
                 :+#%@%%:-#@@@@@@.-#@@@@=:#@@@@**@@@@[email protected]@@@@@@@@@@@@@@@@@@       
                     %+***+: ...      ::..-+*#%#:.-+#..#@@@@@@@@@@@@@@@@@.      
                   :%%**+=:=*.         .+- :+*###%-     .*@@@@@@@@@@@@@@@:      
                   %@@@@@*++ *.        * .#@@@@@[email protected]=     [email protected]@+.=%@@@@@@@@@       
                  :@@@@@@#[email protected]=       .= [email protected]@@@@@@@@%     :%: =#++###@@@@*       
                   @@@@@@@@@=+:        +:[email protected]@@@@@@@@%        =+   [email protected]@@@:       
                   :#%#%%#**#=         :*==++##*#%#.        -#:    [email protected]@@-        
                     :**=++=.            =++++=+=.           .=#:  %@*:         
                      -- .-+--          .=+*+--.             -*#-.#+            
                      .+ -:-  +----:---+:..-  [email protected]:         .%=::=#%-             
                       =- @%- -   =    -   *=+%@=         #.-++=:               
                        =+--=-*-==#=-==*=-+=::.+        .*:                     
                         .*++-= - :. -  = ::=+:       -*+.                      
                           :**+==--+-=--=--:     :=**+-                         
                              :+*++===:        -#=.                             
                                   ..:-+       *:                               
                                       .       ..                               
          ++**##############***************************####%%%%%%%%###=         
          #%%%#####****++++=============------====+++++++++++++++++***-         
                                      ..  .....     ...       .:::::..          
          %%@@@@@@@@@:%@@@@@@@@@[email protected]@@@@@@[email protected]##%@     @@@.      *@@@@@@@*         
          @@@@@@@@@@@-#@%@@@%*%@[email protected]@%**@@*[email protected]  [email protected]     @@@.      *@@====-:         
          @@@+..  *@@=#= [email protected]@= :*:@@*  %@*[email protected]:.:@     @@@.      #@#               
          %@@-     ..    :@@=    @@#  *@*[email protected]@@@@***+ @@@:      #@@+++++=         
          #@@@#######+   :@@=   [email protected]@*-:#@*[email protected]      [email protected] @@@:      #@@*+***=         
          -======-#@@#   :@@+   [email protected]@-  [email protected]#[email protected]:     :@[email protected]@@:      #@@:              
          .-:     [email protected]@#    @@*   :@@-  [email protected]#[email protected]     [email protected]@@@*==---.*@@*:::-:         
          [email protected]@-:::-*@@%    @@*   :@@=  [email protected]#[email protected]#=====*@.%@@@@@@@@=*@@@@@@@%         
          .::::::::...    ..     ..   .::.---:::::: :::::::::..::::::::         
          :+++++*********++=.+++++++++++--**  ++++- -*+=-+++++++  -+++.         
          [email protected]@%%%%@@@@#***%@@[email protected]@#[email protected]@*[email protected]@  @@@@* [email protected]@#*@@@@@@@. *@@@-         
          :%*    @@@*    :@@[email protected]@+      @@#[email protected]@  @@@@# [email protected]@#*@@@@@@@- *@@@-         
                 %@@*       :@@#      %@#[email protected]@. @@@@# [email protected]@#*@@@@@@@+ *@@@-         
                 %@@#       :@@#      #@#[email protected]@- @@@@% [email protected]@#[email protected]@[email protected]@@* #@@@=         
                 #@@#       :@@%      *@%[email protected]@#*@@@@@-#@@%[email protected]@- @@@@=%@@@+         
                 #@@#       [email protected]@@......*@%[email protected]@@@@: %@@@@@%[email protected]@- @@@@@@@@@+         
                 *%%*        ############.#####. +#####+:##: %%%%%%%##-         
          .......................::::::::::::::::.........        .....         
          [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         
                             ...........        ..............      

*/

pragma solidity ^0.8.17;

import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

/// @title StableTown's Genesis Mint, The Stabletons
/// @author Mayor
contract Stabletons is ERC721AQueryable, OperatorFilterer, Ownable, ReentrancyGuard, ERC2981 {
    using SafeERC20 for IERC20;

    // Custom errors
    error OnlyOneCallPerBlockForNonEOA();
    error MaxSupplyExceeded();
    error MaxWLMintsPerWalletExceeded();
    error InvalidTokenType();
    error InsufficientFunds();
    error InvalidQuantity();
    error SaleStateNotActive();
    error InvalidMaxSupply();
    error NonexistentToken();
    error NotOwnerOfToken();
    error TransferFailed();
    error NonMintedTokenId();
    error TokenTypeNotFound();
    error InsufficientTokenAllowance();
    error InsufficientTokenBalance();
    error NotWhitelisted();

    // Event to help with indexing
    event FundsRedeemed(
        address recipient,
        uint256 tokenId,
        TokenType tokenType,
        uint256 amount
    );

    // Enums to represent custom state types
    enum TokenType { Invalid, USDC, USDT, BUSD, DAI }

    enum SaleState {
        Closed,
        Whitelist,
        Public
    }

    // Structs for data organization
    struct TokenDetails {
        IERC20 tokenInterface;
        uint256 depositAmount;
    }

    struct Metadata {
        string usdc;
        string usdt;
        string busd;
        string dai;
    }

    /*///////////////////////////////////////////////////////////////
                                SETTINGS
    //////////////////////////////////////////////////////////////*/

    bool public operatorFilteringEnabled;

    bytes32 public merkleRoot;

    uint256 public maxSupply = 1500;
    uint256 public prefundedMintsRemaining = 0;
    uint256 public constant MAX_MINT_PER_TX = 10;
    uint256 public constant MAX_WL_MINT_PER_WALLET = 10;

    mapping(TokenType => string) private baseTokenURI;
    mapping(TokenType => TokenDetails) public tokens;
    mapping(uint256 => TokenType) public stabletonsDepositType;

    // track last calls from smart contracts for preventing multi-minting
    mapping(address => uint256) public lastCallFrom;
    mapping(address => uint256) public totalWhitelistMint;

    SaleState private saleState;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() ERC721A("Stabletons", "STBL") {
        // initialize token types
        uint256 usdDepositAmount = 10;
        uint256 sixDecimalDeposit = usdDepositAmount * (10**6);
        uint256 eighteenDecimalDeposit = usdDepositAmount * (10**18);
        
        tokens[TokenType.USDC] = TokenDetails(IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48), sixDecimalDeposit);
        tokens[TokenType.USDT] = TokenDetails(IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7), sixDecimalDeposit);
        tokens[TokenType.BUSD] = TokenDetails(IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53), eighteenDecimalDeposit);
        tokens[TokenType.DAI] = TokenDetails(IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F), eighteenDecimalDeposit);

        // setup operator filterer and royalties
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        _setDefaultRoyalty(msg.sender, 750);
    }

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier limitNonEOACallsPerBlock() {
        if (msg.sender != tx.origin) {
            if (lastCallFrom[tx.origin] == block.number) {
                revert OnlyOneCallPerBlockForNonEOA();
            }
            lastCallFrom[tx.origin] = block.number;
        }
        _;
    }

    modifier verifySaleState(SaleState requiredState) {
        if (saleState != requiredState) revert SaleStateNotActive();
        _;
    }

    modifier verifyQuantity(uint256 _quantity) {
        if (_quantity < 1 || _quantity > MAX_MINT_PER_TX) revert InvalidQuantity();
        _;
    }

    modifier verifyAvailableSupply(uint256 _quantity) {
        if (totalMinted() + _quantity > maxSupply) revert MaxSupplyExceeded();
        _;
    }

    modifier verifyTokenType(TokenType _tokenType) {
        if (_tokenType == TokenType.Invalid) revert InvalidTokenType();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                              MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice public mint function for minting a number of NFTs with the same deposit token type
    /// @param _quantity number of tokens to mint
    /// @param _tokenType the type of token to deposit into the NFT: 1 - USDC, 2 - USDT, 3 - BUSD, 4 - DAI
    function publicMint(
        uint256 _quantity,
        TokenType _tokenType
    )
        external 
        payable 
        nonReentrant
        limitNonEOACallsPerBlock
        verifySaleState(SaleState.Public)
        verifyQuantity(_quantity)
        verifyTokenType(_tokenType)
        verifyAvailableSupply(_quantity)
    {
        regularMint(_quantity, _tokenType);
    }

    /// @notice whitelist mint function to allow 1 free NFT with deposit already included; otherwise acts as regular mint
    /// @param _merkleProof proof for verifying against merkle root to confirm whitelist status
    /// @param _quantity number of tokens to mint
    /// @param _tokenType the type of token to deposit into non team-backed NFTs: 1 - USDC, 2 - USDT, 3 - BUSD, 4 - DAI
    function whitelistMint(
        bytes32[] calldata _merkleProof,
        uint256 _quantity,
        TokenType _tokenType
    )
        external
        payable
        nonReentrant
        limitNonEOACallsPerBlock
        verifySaleState(SaleState.Whitelist)
        verifyQuantity(_quantity)
        verifyTokenType(_tokenType)
        verifyAvailableSupply(_quantity)
    {
        // limit maximum WL mints per wallet
        if ((totalWhitelistMint[msg.sender] + _quantity) > MAX_WL_MINT_PER_WALLET) revert MaxWLMintsPerWalletExceeded();

        //create leaf node and verify sender is whitelisted
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verifyCalldata(_merkleProof, merkleRoot, sender)) revert NotWhitelisted();

        uint256 currentUserWLMintCount = totalWhitelistMint[msg.sender];
        totalWhitelistMint[msg.sender] += _quantity;

        // allow free mint if WL user has not claimed yet and if we have remaining funded NFTs
        if (currentUserWLMintCount < 1 && prefundedMintsRemaining > 0) {
            prefundedMintsRemaining--;
            stabletonsDepositType[totalMinted()] = TokenType.USDC;
            if (_quantity > 1) {
                stabletonsDepositType[totalMinted() + 1] = _tokenType;
                requestFundsForTokenMint(_quantity - 1, _tokenType);
            }
            _safeMint(msg.sender, _quantity);
        } else {
            regularMint(_quantity, _tokenType);
        }
    }

    function regularMint(uint256 _quantity, TokenType _tokenType) private {
        stabletonsDepositType[totalMinted()] = _tokenType;
        requestFundsForTokenMint(_quantity, _tokenType);
        _safeMint(msg.sender, _quantity);
    }

    /// @notice private function used to request deposit funds for mint
    /// @dev user must give allowance to this smart contract to allow transfer of their stablecoin
    /// @param _quantity number of tokens to fund
    /// @param _tokenType the type of token to deposit into the NFTs: 1 - USDC, 2 - USDT, 3 - BUSD, 4 - DAI
    function requestFundsForTokenMint(uint256 _quantity, TokenType _tokenType) private {
        TokenDetails memory tokenDetails = tokens[_tokenType];
        uint256 tokenAmount = tokenDetails.depositAmount * _quantity;

        IERC20 tokenInterface = tokenDetails.tokenInterface;

        uint256 allowance = tokenInterface.allowance(msg.sender, address(this));
        if (allowance < tokenAmount) revert InsufficientTokenAllowance();
        if (tokenInterface.balanceOf(msg.sender) < tokenAmount) revert InsufficientTokenBalance();

        tokenInterface.safeTransferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );
    }

    /*///////////////////////////////////////////////////////////////
                              BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice public mint function for burning and redeeming stablecoins from an NFT that you own
    /// @param tokenId the token id of the NFT to burn and redeem stablecoin value from
    function redeemFunds(uint256 tokenId) external nonReentrant {
        if (!_exists(tokenId)) revert NonexistentToken();
        if (ownerOf(tokenId) != msg.sender) revert NotOwnerOfToken();

        _burn(tokenId);
        _resetTokenRoyalty(tokenId);

        TokenType tokenType = getStabletonTokenType(tokenId);

        TokenDetails memory tokenDetails = tokens[tokenType];
        uint256 tokenAmount = tokenDetails.depositAmount;

        IERC20 tokenInterface = tokenDetails.tokenInterface;

        emit FundsRedeemed(msg.sender, tokenId, tokenType, tokenAmount);

        tokenInterface.safeTransfer(
            msg.sender,
            tokenAmount
        );
    }

    /// @notice helper function for returning the stablecoin deposit type of the NFT
    /// @dev we are using a backwards lookup corresponding to the stabletonsDepositType mapping to save gas
    /// @param tokenId the token id of the NFT to get the TokenType of
    /// @return TokenType deposit of the given NFT
    function getStabletonTokenType(uint256 tokenId) public view returns(TokenType) {
        if (tokenId < 0 || tokenId >= totalMinted()) revert NonMintedTokenId();

        uint256 lowestTokenToCheck;
        if (tokenId >= MAX_MINT_PER_TX) {
            lowestTokenToCheck = tokenId - MAX_MINT_PER_TX + 1;
        }

        for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
            TokenType possibleTokenType = stabletonsDepositType[curr];
            if (possibleTokenType != TokenType.Invalid) {
                return possibleTokenType;
            }
        }

        revert TokenTypeNotFound();
    }

    /*///////////////////////////////////////////////////////////////
                                METADATA
    //////////////////////////////////////////////////////////////*/

    function getBaseURI(uint256 tokenId) internal view returns (string memory) {
        TokenType tokenType = getStabletonTokenType(tokenId);
        return baseTokenURI[tokenType];
    }

    function setSpecificBaseTokenURI(TokenType _token, string calldata _uri) external onlyOwner {
        baseTokenURI[_token] = _uri;
    }

    function setBaseTokenURI(Metadata calldata _metadata) external onlyOwner {
        baseTokenURI[TokenType.USDC] = _metadata.usdc;
        baseTokenURI[TokenType.USDT] = _metadata.usdt;
        baseTokenURI[TokenType.BUSD] = _metadata.busd;
        baseTokenURI[TokenType.DAI] = _metadata.dai;
    }

    /// @notice Returns the URI for a given token's metadata
    /// @dev the baseURI for the tokens are different depending on the deposit TokenType
    /// @param tokenId the token ID of interest
    /// @return URI for this token
    function tokenURI(uint256 tokenId) public view virtual override (IERC721A, ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentToken();

        string memory baseURI = getBaseURI(tokenId);
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
	}

    /*///////////////////////////////////////////////////////////////
                            UPDATE SETTINGS
    //////////////////////////////////////////////////////////////*/

    function setSaleState(SaleState _saleState) external onlyOwner {
        saleState = _saleState;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        if (_maxSupply < totalMinted()) revert InvalidMaxSupply();
        maxSupply = _maxSupply;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /*///////////////////////////////////////////////////////////////
                        PUBLIC HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getSaleState() public view returns (SaleState) {
        return saleState;
    }

    function isAlive(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }

    function getOwnershipAt(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipAt(index);
    }

    function getOwnershipOf(uint256 tokenId) public view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                      TEAM DEPOSITS AND WITHDRAWALS
    //////////////////////////////////////////////////////////////*/

    /// @notice only owner function to deposit USDC for prefunded whitelist mints
    /// @dev requires allowance for this smart contract to transfer USDC
    /// @param _mintsToPrefund the amount of mints we want to prefund
    function teamDepositUSDC(uint256 _mintsToPrefund) external onlyOwner {
        prefundedMintsRemaining += _mintsToPrefund;
        requestFundsForTokenMint(_mintsToPrefund, TokenType.USDC);
    }

    /// @notice only owner function to withdraw any unused team USDC deposits
    /// @dev this exists for the scenario where not all prefunded mints are claimed
    function withdrawUnusedTeamDepositUSDC() external onlyOwner {
        TokenDetails memory tokenDetails = tokens[TokenType.USDC];
        uint256 tokenAmount = tokenDetails.depositAmount * prefundedMintsRemaining;

        prefundedMintsRemaining = 0;
        IERC20 tokenInterface = tokenDetails.tokenInterface;

        tokenInterface.safeTransfer(
            msg.sender,
            tokenAmount
        );
    }

    /// @notice only owner function to withdraw ETH
    function withdrawETH() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    /*///////////////////////////////////////////////////////////////
                    OPERATOR FILTERER AND ROYALTIES
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved)
        public
        override (IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}