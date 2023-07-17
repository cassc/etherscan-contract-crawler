//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./ERC721ASGakuen.sol";

//
//
//                                              [Note from Dev]
//                                         PRAISE THE KAORI-CHAN!!!!!
//
//                                                .::-----:::.
//                                         :=+#%%%@@@@@%%%#####*+=-.
//                                .-===-=#@@@@@@@@@@@%%###########***=-.
//                             -+*#******#######%@@@%#####%##########***+-
//                          -*##%###*********#***##%%@###**#%%%########***#=
//                       .+%%%@@###########%@@######*##%*##***#@%########**%#-
//                     :*@@@@@%%@@@@@@@@@@@@@@@#%@@%##########**#@%#########%#*:
//                    *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%############%@%########%##=
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%@@%%####%@%#%#####%##=
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@#*%@@@%%%%%@@%%%%##@###+
//              [email protected]@@@@@@@@@@@@@@@@@@@@#*@@@@@@@@@@@@@@@@@@@#*@@@@@%%%%@@@%%%%%@%%#+
//             =%*@@@@@@@@@@@@@@@@@@@@+:#@@@@@@@@@@@@@@@@@@@@#*@@@@@@@%%@@@@@%%@%%%%-
//           .++*%@@@@@@@@@@@@@@@@@@@=:.%@@@@@@@@@@@@@%@@@@@@@%%@@@#%@@%@@@@@@@@@%%%#
//          .-.**@@@@@@@@@@@@@@@@@@@=.  %@@@@@@@@@@@@@@%%@@@@@@@@%:=%@@@%@@@@@@@@@@@%+
//          - +*#%@@@@@@@@@@@@@@@@@+    %@@@@@@@@@@@@@@@@%=-=+*%#:*@@@@@@%@@@@@@@@@@@%.
//         .:.-*#%@@@@@@*@@@@@@@@@*     #@*[email protected]@@@@%@@@@@@@@@@@%#-=%%#%@@@@@@@@@@@@@@@@@+
//         . :.#*%@@@@@##@@@@@@@@%      [email protected]%+%%@@@@#%@@@@@@@@@#:#@@@@@**@@@@@@@@@%@@@@@%
//         .=  %+%@@@@@*@@@@@@#@@:      [email protected]@#@@@@@@@%@@@@@@@@=+#@@@%%@@%#@@@@@@@@%%@@@@@:
//         := :@*@@@@@@@@@[email protected]@*[email protected]*       .#@@@@@@@@@@@@@@@@@#%@@@@@%=#+.*@@@%@@@@**@@@@@-
//         .: [email protected]%%@@@@@@@[email protected]@:[email protected]:        [email protected]%@@@@@@*@@@@@@@@@@#===+*#:=%@@@@#@@@%::@@@@@+
//         .  [email protected]@@@@@@@@=. =+  *         .=**@@%@@#*@@@@@@@@@@@@@%*:#%#%%@@+#@@+-.#@@@@*
//         ...-#@@@@@@@%.:. .             .--:*#+%@-:*@@@@@@@@@@@[email protected]@@@@%+#[email protected]%=++*@@@@#
//          .. :*@@@@@@#@@##%+:              .    :=. .=*%@@@@@*=#%@@@@@#@@-#@%####@@@@%
//          .. ..=#@@@@+%: #@@@#.                 .....  .:%@@@#@@@@@#@#@@#[email protected]@@@@@%@@@@%
//           -  .:.*@@@+.. #@@*@@:             -#@@@@@@#@@=**#@@@@%#+*@@@@-*@@@@@@@@@@@@
//                :*@%@+.  [email protected]@@@#             :%:[email protected]@@:@@**#@*[email protected]@@@#*#@@@@[email protected]%@@@@@@@@@@%
//                 .*%%-   .-++-                 [email protected]@@*@@= +-:@@@@@@@@@@@*=:*%@@@@@@@@@@*
//                 .*-%+.                        .#@@@#:   .+*@@@@@@@@@%**[email protected]@@@@@@@@@@-
//                 %#%@:                          ...      [email protected]@@@@@%*@@* --%@@@@@@@@@@*.
//                #@%@@-                                  =%#@@@@@..**::[email protected]@@@@@@@@@%=
//               :@-#@@+                                 :. :@@@@%.-=+:=*#@@@@@@@@@@%*=
//               *= [email protected]%+-                                  [email protected]@@@*+.=#[email protected]@@@@@@@@@@%%-
//               #  :%* .=.                               -#%@@@%##%+=+%@@@@@@@@@@@@@#
//               +   =- [email protected]%-     .=---:.                -*%#%@@#*==*[email protected]@@@@@@@@@@@@@@@.
//               =   *=*+-. =: .+-  -+              .---.#%%@@%#+=*#%@@@@@@@@@@@@@@@-
//                * :=  .  . =%#:   =-          :---:[email protected]@@@%%##%@@@@@@@@@@@@@@@@@=
//                 -..    ::[email protected]++:. #      :-=++-. [email protected]@@@@%%@@@@@@@@@@@@@@@@@%:
//                       -:::-*#+=+*=.::+%%*=-.     . .:----+%%@@@#*@@@@@#+=#@%*=.
//                                      =#-.        .:. :   . ==-. . ::.   .:.
//                                      -:               .
//                                      :                :
//                                      :                =.           ... .
//                                      -                 =..:::::...:..  .=+.
//                                     :.                 ::.::..:==:       -%+
//                                    :-               .--:::-:-+%*.         -%#
//                                 .:--              .=%%%##*-:#@*            +%=
//                              .::.              ..+%%%@@@*[email protected]@+##:         :%%
//                -=++*##%@%-               .....:+%%*##%#- .*@@@@+-.         :*@=
//               :#######+==-.           ...   -*@%+*++::   [email protected]@@@+===.    ..:.:-#%
//               -=+++=*+--::-=:     ..     :[email protected]@@@+=:::    =%@@@@#+++-.:::::::::-
//               :::::::...  .:-         .=%@@@@@#-.   .  .#@@@@+===-:::........:
//               .... .      :+#%+:   .:=*%@@@#=:.-.      [email protected]@@#=:..             :
//             .     ..    .-+*##**=+#%@@@@@*--+%@-     [email protected]%-                 -
//             :    ::...::-=*#%%%%%%@@@@@@##@@@%.      =#[email protected]=                 .-
//        .    :. :-::::::-===+++*%%###%@@@@@%*-        #%@@.                 :.
//         ... -:==-::.. .:--=--=+**#%%%%%#*-.         .#@@%                 .-
//           .-+==-.    .:-----=*+===++*=-.             @@@-                .::
//           +=-:          .:-=-:.:---..               :@@#                 .=
//         :-:.            ..   .:..                   [email protected]@.                ..-
//
//
//  @@@@@%[email protected]@@@@[email protected]@@@%#: =%@@@#-           -#@@@%+  [email protected]@@@#  %@@[email protected]@#[email protected]@%.%@@:[email protected]@@@@.*%%- %%#
// .=*@@@:%@@*[email protected]@+:@@#*@@#[email protected]@@[email protected]@#-+#@@#:@@@[email protected]@@: %@@@@# [email protected]@%[email protected]@# [email protected]@.:@@@ %@*==+ @@@#[email protected]@+
//  [email protected]@@-.%@#=- %@#*=#@[email protected]@@[email protected]@* *@@[email protected]@* *@@* === [email protected]@[email protected]@# [email protected]@*%@#  %@@:[email protected]@*.%@#=- [email protected]@@@#@@:
// [email protected]@@- [email protected]@@@#[email protected]@@@@@*[email protected]@@ %@@-  [email protected]@@@+  @@@ @@@#[email protected]@@:@@# #@@@@@+ [email protected]@@[email protected]@[email protected]@@@#.*@@%@@@@
//[email protected]@@=  #@#=  [email protected]@%:@@%*@@*:@@@  .%@[email protected]%::@@@  %@=*@@@@@@#[email protected]@%-%@% [email protected]@%:%@@ #@#=   @@#[email protected]@@+
//%@@@@@[email protected]@@@@+%@@[email protected]@[email protected]@%%@@- :@@#-+#@@[email protected]@@@@@@[email protected]@@:*@@*[email protected]@=.*%@[email protected]@@@@@[email protected]@@@@[email protected]@=:@@@:
//
//
/// @title 0xGakuen NFT smart contact
/// @author Comet, JayB
contract ZeroXGakuen is ERC721ASGakuen, Ownable, ReentrancyGuard {
    // 0b'00000111
    // We can know amount user purchased by
    // (purchasedInfo >> Identifier) & AMOUNT_MASK
    uint256 internal constant AMOUNT_MASK = uint256(7);
    //0b'1111...1000
    uint256 internal constant PUBLIC_CLEAR_MASK = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8;

    string private baseURI;
    bool private hasExtention;

    // Compiler will pack it into uint256
    struct PrivateSaleConfig {
        // [uint32 for time]
        // Maximum value of uint32 == 4294967295 > Feb 07th, 2106
        // Therefore, Impossible to overflow

        // [Private Sale Config Structure]
        // startTime      : time when sale starts
        // endTime        : time when sale ends
        // identifier : parameter to identify personal purchase info
        //                  see purchaseInfo
        // merkleRoot     : merkleRoot to manage whitelist
        // perosonalLimit : amount user can purchase, lte 3
        //
        // data above will be 120 bits
        // and there will be pair of data
        // so it is 240 bits
        // 
        // totalPurchase is 16bits, 240+16 = 256 bits it will be packed as
        //
        uint32    firstStartTime;
        uint32    firstEndTime;
        // identifier also used as sale mask.
        // it should be >>3
        uint8     firstIdentifier;
        bytes32   firstMerkleRoot;
        uint8     firstPersonalLimit;

        uint32    secondStartTime;
        uint32    secondEndTime;
        // identifier also used as sale mask.
        // it should be >>6
        uint8     secondIdentifier;
        bytes32   secondMerkleRoot;
        uint8     secondPersonalLimit;

        // Keep track of total purchased amount to calculate public sale total limit
        // Max value of uint16 is 65535, so there will be never overflow
        uint16    totalPurchased;
    }
    PrivateSaleConfig private privateSaleConfig;

    // Compiler will pack it into uint256
    struct GeneralSaleConfig {
        // [uint32 for time]
        // Maximum value of uint32 == 4294967295 > Feb 07th, 2106
        // Therefore, Impossible to overflow
        uint32    startTime;
        uint32    endTime;
        // identifier also used as sale mask.
        // it should be >> 0 for public sale
        uint8     identifier;
        bytes32   merkleRoot;
        uint8     personalLimit;
        uint16    totalLimit;
        uint16    totalPurchased;
    }
    GeneralSaleConfig private publicSaleConfig;

    struct PurchaseLimitation {
      uint128 totalLimit;
      uint128 reserved;
    }
    PurchaseLimitation public limitation = PurchaseLimitation({
      totalLimit: 4649, reserved: 150
    });

    // purchasedInfo : keep track of amount user minted
    // right 3bit keeps track of pulbic mint.
    mapping(address => uint256) public purchasedInfo;

    // IERC-2981 royalty info in percent, decimal
    uint256 public royaltyRatio = 5;

    // To minimize gas cost, set real mint price as default value
    // there is only small chance to change price between deploy and minting
    uint256 public privatePrice = 0.03 ether;
    uint256 public publicPrice = 0.05 ether;
    event ChangedPrivateSaleConfig(
        uint32    firstStartTime,
        uint32    firstEndTime,
        uint8     firstIdentifier,
        bytes32   firstMerkleRoot,
        uint8     firstPersonalLimit,

        uint32    secondStartTime,
        uint32    secondEndTime,
        uint8     secondIdentifier,
        bytes32   secondMerkleRoot,
        uint8     secondPersonalLimit
    );

    event ChangedPublicSaleConfig(
        uint32    startTime,
        uint32    endTime,
        uint8     identifier,
        uint8     personalLimit
    );

    constructor() ERC721ASGakuen("0xGakuen", "ZXG") {}

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Contract call from another contract is not allowed"
        );
        _;
    }

    /// @notice Mint additional NFT for owner
    /// @dev use it for marketing, etc.
    /// @param receiver address who will receive nft
    /// @param numOfTokens NFTs will be minted to owner
    function ownerMintTo(address receiver, uint256 numOfTokens) external payable onlyOwner {
        _mint(receiver, numOfTokens);
    }

    /// @notice private sale Mint
    /// @dev merkleProof should be calculated on frontend to prevent gas.
    /// @dev frontend would submit the merkleProof based on user addr
    /// @param merkleProof is proof calculated on frontend
    /// @param identifier is bit need to shift
    /// @param numOfTokens is amount user will mint
    function privateMint(bytes32[] memory merkleProof, uint256 identifier, uint256 numOfTokens)
        external
        payable
        nonReentrant
        callerIsUser
    {
        PrivateSaleConfig memory psc = privateSaleConfig;
        uint256 currentTime = block.timestamp;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        GeneralSaleConfig memory saleConfig;
        uint256 amount;
        uint256 price = privatePrice;

        if(psc.firstIdentifier == identifier) {
          saleConfig.startTime = psc.firstStartTime;
          saleConfig.endTime = psc.firstEndTime;
          saleConfig.identifier = psc.firstIdentifier;
          saleConfig.merkleRoot = psc.firstMerkleRoot;
          saleConfig.personalLimit = psc.firstPersonalLimit;
          amount = numOfTokens;
        } else if (psc.secondIdentifier == identifier) {
          saleConfig.startTime = psc.secondStartTime;
          saleConfig.endTime = psc.secondEndTime;
          saleConfig.identifier = psc.secondIdentifier;
          saleConfig.merkleRoot = psc.secondMerkleRoot;
          saleConfig.personalLimit = psc.secondPersonalLimit;
          amount = psc.secondPersonalLimit;
        } else {
          revert('No Identifier Matched');
        }

        require(
            MerkleProof.verify(merkleProof, saleConfig.merkleRoot, leaf),
            "Not listed"
        );

        require(
            saleConfig.startTime != 0 &&
                currentTime >= saleConfig.startTime &&
                currentTime < saleConfig.endTime,
            "Out of sale period"
        );

        require(
            saleConfig.totalPurchased + amount <= limitation.totalLimit-limitation.reserved,
            "Mint will exceed total limit"
        );


        uint256 _purchasedInfo = purchasedInfo[msg.sender];
        uint256 purchased = ((_purchasedInfo>>saleConfig.identifier) & AMOUNT_MASK);
        require((purchased+amount) <= saleConfig.personalLimit, "Personal Limit Overflow");
        
        uint256 cost = price * amount;
        require(msg.value >= cost, "ETH is not sufficient");

        // it will be not bug since personalLimit is lte 3
        purchasedInfo[msg.sender] = _purchasedInfo | ((purchased+amount) << saleConfig.identifier);
        privateSaleConfig.totalPurchased += uint16(amount);
        _mint(msg.sender, amount);
    }

    /// @notice Public Sale Mint
    /// @dev To finish sale earlier, call finishSale()
    /// @param numOfTokens NFTs will be minted to msg.sender
    function publicMint(uint256 numOfTokens)
        external
        payable
        nonReentrant
        callerIsUser
    {
        GeneralSaleConfig memory saleConfig = publicSaleConfig;
        uint256 currentTime = block.timestamp;
        uint256 startTime = saleConfig.startTime;
        uint256 endTime = saleConfig.endTime;

        require(
            startTime != 0 &&
                currentTime >= startTime &&
                currentTime < endTime,
            "Out of sale period"
        );

        require(
            saleConfig.totalPurchased + privateSaleConfig.totalPurchased + numOfTokens <= limitation.totalLimit - limitation.reserved,
            "Mint will exceed total limit"
        );

        uint256 _purchasedInfo = purchasedInfo[msg.sender];
        uint256 purchased = _purchasedInfo & AMOUNT_MASK;

        require(
            (purchased + numOfTokens) <=
                saleConfig.personalLimit,
            "Mint will exceed personal limit"
        );

        uint256 cost = publicPrice * numOfTokens;
        require(msg.value >= cost, "ETH is not sufficient");
        purchasedInfo[msg.sender] += numOfTokens;
        publicSaleConfig.totalPurchased += uint16(numOfTokens);

        _mint(msg.sender, numOfTokens);
    }

    /// @notice change the price
    /// @param _privatePrice privatePrice will be set to it
    /// @param _publicPrice publicPrice will be set to it 
    function setPrice(uint256 _privatePrice, uint256 _publicPrice)
        external
        onlyOwner
    {
        privatePrice = _privatePrice;
        publicPrice = _publicPrice;
    }

    /// @notice change the totalLimit
    /// @param _totalLimit is totalLimit will be set to it 
    function setPurchaseLimitation(uint256 _totalLimit, uint256 _reserved) external onlyOwner
    {
      limitation.totalLimit = uint128(_totalLimit);
      limitation.reserved = uint128(_reserved);
    }

    function setPrivateSaleConfig(
        uint32    firstStartTime,
        uint32    firstEndTime,
        uint8     firstIdentifier,
        bytes32   firstMerkleRoot,
        uint8     firstPersonalLimit,
        uint32    secondStartTime,
        uint32    secondEndTime,
        uint8     secondIdentifier,
        bytes32   secondMerkleRoot,
        uint8     secondPersonalLimit
    ) external onlyOwner {
        PrivateSaleConfig memory saleConfig = privateSaleConfig;

        saleConfig.firstStartTime        = firstStartTime;
        saleConfig.firstEndTime          = firstEndTime;
        saleConfig.firstIdentifier       = firstIdentifier;
        saleConfig.firstMerkleRoot       = firstMerkleRoot;
        saleConfig.firstPersonalLimit    = firstPersonalLimit;

        saleConfig.secondStartTime         = secondStartTime;
        saleConfig.secondEndTime           = secondEndTime;
        saleConfig.secondIdentifier        = secondIdentifier;
        saleConfig.secondMerkleRoot        = secondMerkleRoot;
        saleConfig.secondPersonalLimit     = secondPersonalLimit;

        privateSaleConfig = saleConfig;
        emit ChangedPrivateSaleConfig(
            firstStartTime,
            firstEndTime,
            firstIdentifier,
            firstMerkleRoot,
            firstPersonalLimit,

            secondStartTime,
            secondEndTime,
            secondIdentifier,
            secondMerkleRoot,
            secondPersonalLimit
        );
    }

    function setPublicSaleConfig(
        uint32    startTime,
        uint32    endTime,
        uint8     identifier,
        uint8     personalLimit
    ) external onlyOwner {
        GeneralSaleConfig memory saleConfig   = publicSaleConfig;
        saleConfig.startTime                  = startTime;
        saleConfig.endTime                    = endTime;
        saleConfig.identifier                 = identifier;
        saleConfig.personalLimit              = personalLimit;

        publicSaleConfig = saleConfig;

        emit ChangedPublicSaleConfig(
            startTime,
            endTime,
            identifier,
            personalLimit
        );
    }

    function getPrivateSaleConfig() external view returns(
        uint32    firstStartTime,
        uint32    firstEndTime,
        uint8     firstIdentifier,
        uint8     firstPersonalLimit,
        uint32    secondStartTime,
        uint32    secondEndTime,
        uint8     secondIdentifier,
        uint8     secondPersonalLimit,
        uint16    totalPurchased
    ) {
        PrivateSaleConfig memory saleConfig = privateSaleConfig;

        firstStartTime        = saleConfig.firstStartTime;
        firstEndTime          = saleConfig.firstEndTime;
        firstIdentifier       = saleConfig.firstIdentifier;
        firstPersonalLimit    = saleConfig.firstPersonalLimit;

        secondStartTime         = saleConfig.secondStartTime;
        secondEndTime           = saleConfig.secondEndTime;
        secondIdentifier        = saleConfig.secondIdentifier;
        secondPersonalLimit     = saleConfig.secondPersonalLimit;
        totalPurchased           = saleConfig.totalPurchased;
    }

    function getPublicSaleConfig() external view returns(
        uint32    startTime,
        uint32    endTime,
        uint8     identifier,
        uint8     personalLimit,
        uint16    totalPurchased
    ) {
        GeneralSaleConfig memory saleConfig   = publicSaleConfig;
        startTime                             = saleConfig.startTime;
        endTime                               = saleConfig.endTime;
        identifier                            = saleConfig.identifier;
        personalLimit                         = saleConfig.personalLimit;
        totalPurchased                        = saleConfig.totalPurchased;
    }

    function getTotalPurchased() external view returns(uint256 totalPurchased) {
      totalPurchased = privateSaleConfig.totalPurchased
                      + limitation.reserved
                      + publicSaleConfig.totalPurchased;
    }

    /// @notice Change baseURI
    /// @param _newURI is URI to set
    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    /// @notice Change hasExtention
    /// @param _newState is new state to set
    function setHasExtention(bool _newState) external onlyOwner {
        hasExtention= _newState;
    }

    /// @dev override baseURI() in ERC721ASGakuen
    function _baseURI()
        internal
        view
        override(ERC721ASGakuen)
        returns (string memory)
    {
        return baseURI;
    }

    /// @dev override _hasExtention() in ERC721ASGakuen
    function _hasExtention()
        internal
        view
        override(ERC721ASGakuen)
        returns (bool)
    {
        return hasExtention;
    }

    
    /// @dev override _startTokenId() in ERC721ASGakuen
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    /// [email protected] this function will increase the schoolingId, and will reset the whole checkpoint
    /// @dev use this function to start next schooling period
    /// @param _begin _schoolingPolicy.schoolingBegin will be set to it
    /// @param _end _schoolingPolicy.schoolingEnd will be set to it
    /// @param _breaktime _schoolingPolicy.breaktime will be set to it
    function _applyNewSchoolingPolicy(
        uint256 _begin,
        uint256 _end,
        uint256 _breaktime
    ) external onlyOwner {
        _applyNewSchoolingPolicy(
            uint40(_begin),
            uint40(_end),
            uint40(_breaktime)
        );
    }
 
    /// @dev this function change schoolingBegin without increasing the schoolingId
    /// @dev use this function to fix the value set wrong
    /// @param begin _schoolingPolicy.schoolingBegin will be set to it
    function setSchoolingBegin(uint256 begin) external onlyOwner {
        _setSchoolingBegin(uint40(begin));
    }

    /// @dev this function change schoolingEnd without increasing the schoolingId
    /// @dev use this function to fix the value set wrong
    /// @param end _schoolingPolicy.schoolingEnd will be set to it
    function setSchoolingEnd(uint256 end) external onlyOwner {
        _setSchoolingEnd(uint40(end));
    }

    /// @dev this function change breaktime without increasing the schoolingId
    /// @dev use this function to fix the value set wrong
    /// @param breaktime _schoolingPolicy.breaktime will be set to it
    function setSchoolingBreaktime(uint256 breaktime) external onlyOwner {
        _setSchoolingBreaktime(uint40(breaktime));
    }

    /// @dev add new checkpoint & uri to schoolingURI
    /// @param checkpoint schoolingTotal required to reach this checkpoint
    /// @param uri to be returned when schoolingTotal is gte to checkpoint
    function addCheckpoint(uint256 checkpoint, string memory uri)
        external
        onlyOwner
    {
        _addCheckpoint(checkpoint, uri);
    }

    /// @dev replace existing checkpoint & uri in schoolingURI
    /// @param checkpoint schoolingTotal required to reach this checkpoint
    /// @param uri to be returned when schoolingTotal is gte to checkpoint
    /// @param index means nth element, start from 0
    function replaceCheckpoint(
        uint256 checkpoint,
        string memory uri,
        uint256 index
    ) external onlyOwner {
        _replaceCheckpoint(checkpoint, uri, index);
    }

    /// @dev replace existing checkpoint & uri in schoolingURI
    /// @param index means nth element, start from 0
    function removeCheckpoint(uint256 index) external onlyOwner {
        _removeCheckpoint(index);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /// @dev withdraw balance of smart contract patially
    /// @param amount is the amout to withdraw
    function patialWithdraw(uint256 amount) external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance >= amount, "Not enough balance");
        payable(msg.sender).transfer(balance);
    }

    /// @dev withdraw all balance of smart contract
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setRoylatyInfo(uint256 _royaltyRatio) external onlyOwner nonReentrant {
      royaltyRatio = _royaltyRatio;
    }

    /// @dev see IERC-2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
      _tokenId; // silence solc warning
      receiver = owner();
      royaltyAmount = (_salePrice / 100) * royaltyRatio;
      return (receiver, royaltyAmount);
    } 
}