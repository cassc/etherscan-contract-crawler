// SPDX-License-Identifier: MIT

/*

  $$\   $$$$$$\  $$\   $$\       $$\      $$\                     $$\       $$\                                     
$$$$ | $$$ __$$\ $$ | $$  |      $$ | $\  $$ |                    $$ |      $$ |                                    
\_$$ | $$$$\ $$ |$$ |$$  /       $$ |$$$\ $$ | $$$$$$\   $$$$$$\  $$ | $$$$$$$ |       $$$$$$$\ $$\   $$\  $$$$$$\  
  $$ | $$\$$\$$ |$$$$$  /        $$ $$ $$\$$ |$$  __$$\ $$  __$$\ $$ |$$  __$$ |      $$  _____|$$ |  $$ |$$  __$$\ 
  $$ | $$ \$$$$ |$$  $$<         $$$$  _$$$$ |$$ /  $$ |$$ |  \__|$$ |$$ /  $$ |      $$ /      $$ |  $$ |$$ /  $$ |
  $$ | $$ |\$$$ |$$ |\$$\        $$$  / \$$$ |$$ |  $$ |$$ |      $$ |$$ |  $$ |      $$ |      $$ |  $$ |$$ |  $$ |
$$$$$$\\$$$$$$  /$$ | \$$\       $$  /   \$$ |\$$$$$$  |$$ |      $$ |\$$$$$$$ |      \$$$$$$$\ \$$$$$$  |$$$$$$$  |
\______|\______/ \__|  \__|      \__/     \__| \______/ \__|      \__| \_______|       \_______| \______/ $$  ____/ 
                                                                                                          $$ |      
                                                                                                          $$ |      
                                                                                                          \__|      
*/

pragma solidity ^0.8.7;

import "./IERC721D.sol";
import "./StakeContract.sol";
import "./CryptoPunksMarket.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract _10KWorldCup is IERC721D, ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant WL_PRICE = 0.035 ether;
    uint256 public constant PUB_PRICE = 0.05 ether;
    uint256 public BuilderWL_LIMIT = 8;
    uint256 public SuperWL_LIMIT = 4;
    uint256 public WL_LIMIT = 2;
    uint256 public BCN_LIMIT = 2;
    uint256 public PUB_SALE_LIMIT = 2;
    uint256 public topEightRightTeams;
    uint256 public championTokenIdAmount;
    string public baseTokenURI;
    bool claimStatus;
    uint256 public pubSaleTime = 1667829600;
    address public stakeAddress;
    address public mintSignAddress = 0x66E1A1c2307c5a126ef2837969ae020Ede7d6548;
    address public ClaimSignAddress =
        0x93A0f55968a2050b4bF5B900b5Aa566F304194e2;

    mapping(address => uint256) public minteds;
    mapping(uint256 => bool) bonusCliamed;
    mapping(uint256 => mapping(uint8 => bool)) public bonusInfo;
    mapping(address => mapping(uint256 => uint256)) public bcnTokenIdUsedLimit;
    mapping(address => bool) public disapprovedMarketplaces;

    enum WlType {
        BuilderWl,
        SuperWl,
        LuckyWl,
        CommonWl
    }

    enum ClaimType {
        ChampionBonus,
        TopEightBonus,
        ConsolationPrize
    }

    Bcn supportedBcns;
    struct Bcn {
        address[] _bcnAddress;
        mapping(address => uint256) _index;
    }

    Bonus public bonus;
    struct Bonus {
        uint256 ownerBonus;
        uint256 championBonus;
        uint256 topEightBonus;
        uint256 consolationPrize;
    }

    RemainBonus public remainBonus;
    struct RemainBonus {
        uint256 ownerBonus;
        uint256 championBonus;
        uint256 topEightBonus;
        uint256 consolationPrize;
    }

    event RandomTeam(string indexed country, uint256[]);
    event MintToBcn(
        address indexed to,
        uint256 indexed amount,
        address indexed bcnAddress,
        uint256
    );

    constructor(string memory _baseTokenUri)
        ERC721A("10K World Cup", "10K World Cup")
    {
        baseTokenURI = _baseTokenUri;
    }

    function mint(
        address to,
        uint256 amount,
        bytes calldata _signature
    ) external payable {
        require(block.timestamp >= pubSaleTime, "Not on public sale");
        require(totalSupply() + amount <= MAX_SUPPLY, "Sold out!");
        require(minteds[to] + amount <= PUB_SALE_LIMIT, "Limit exceeded");
        require(msg.value >= amount * PUB_PRICE, "Not paying enough fees");
        require(
            keccak256(abi.encodePacked(to, amount))
                .toEthSignedMessageHash()
                .recover(_signature) == mintSignAddress,
            "Signature fail"
        );
        unchecked {
            minteds[to] += amount;
        }
        _mint(to, amount);
    }

    function wlMint(
        address _owner,
        address to,
        uint256 amount,
        WlType _WlType,
        bytes calldata _singature
    ) external payable {
        require(totalSupply() + amount <= MAX_SUPPLY, "Sold out!");
        require(msg.value >= amount * WL_PRICE, "Not paying enough fees");
        require(
            keccak256(abi.encodePacked(_owner, amount, _WlType))
                .toEthSignedMessageHash()
                .recover(_singature) == mintSignAddress,
            "You're not on the whitelist"
        );

        if (_WlType == WlType.BuilderWl) {
            require(
                minteds[_owner] + amount <= BuilderWL_LIMIT,
                "Limit exceeded"
            );
        } else if (_WlType == WlType.SuperWl) {
            require(
                minteds[_owner] + amount <= SuperWL_LIMIT,
                "Limit exceeded"
            );
        } else if (_WlType == WlType.LuckyWl) {
            require(minteds[_owner] + amount <= WL_LIMIT, "Limit exceeded");
        } else {
            require(minteds[_owner] + amount <= WL_LIMIT, "Limit exceeded");
        }

        unchecked {
            minteds[_owner] += amount;
        }
        _mint(to, amount);
    }

    function mintToBcn(
        uint256 amount,
        address bcn,
        uint256 bcnTokenId,
        bool isCryptoPunks
    ) external payable {
        address to;
        if (isCryptoPunks) {
            to = CryptoPunksMarket(bcn).punkIndexToAddress(bcnTokenId);
        } else {
            to = IERC721A(bcn).ownerOf(bcnTokenId);
        }

        require(to != address(0), "BcnTokenId not exists!");
        uint256 bcnTokenLimit = bcnTokenIdUsedLimit[bcn][bcnTokenId];
        uint256 wlMintedAmount = minteds[to];
        require(
            bcnTokenLimit + amount <= BCN_LIMIT,
            "BcnTokenId is used limit"
        );
        require(this.containsBcn(bcn), "Not support this bcn");
        require(wlMintedAmount + amount <= BCN_LIMIT, "Limit exceeded");
        require(totalSupply() + amount <= MAX_SUPPLY, "Sold out!");
        require(msg.value >= amount * WL_PRICE, "Not paying enough fees");
        unchecked {
            minteds[to] = wlMintedAmount + amount;
            bcnTokenIdUsedLimit[bcn][bcnTokenId] = bcnTokenLimit + amount;
        }
        _mint(to, amount);
        emit MintToBcn(to, amount, bcn, bcnTokenId);
    }

    function addBcn(address[] calldata bcns) external onlyOwner {
        for (uint256 i = 0; i < bcns.length; i++) {
            if (!this.containsBcn(bcns[i])) {
                supportedBcns._bcnAddress.push(bcns[i]);
                supportedBcns._index[bcns[i]] = supportedBcns
                    ._bcnAddress
                    .length;
            }
        }
    }

    function removeBcn(address[] calldata bcns) external onlyOwner {
        for (uint256 i = 0; i < bcns.length; i++) {
            uint256 addressIndex = supportedBcns._index[bcns[i]];
            if (addressIndex != 0) {
                uint256 toDeleteIndex = addressIndex - 1;
                uint256 lastIndex = supportedBcns._bcnAddress.length - 1;
                if (lastIndex != toDeleteIndex) {
                    address lastAddress = supportedBcns._bcnAddress[lastIndex];
                    supportedBcns._bcnAddress[toDeleteIndex] = lastAddress;
                    supportedBcns._index[lastAddress] = addressIndex;
                }
                supportedBcns._bcnAddress.pop();
                delete supportedBcns._index[bcns[i]];
            }
        }
    }

    function containsBcn(address bcn) external view returns (bool) {
        return supportedBcns._index[bcn] != 0;
    }

    function allSupportedBcn() external view returns (address[] memory) {
        return supportedBcns._bcnAddress;
    }

    function lengthBcn() external view returns (uint256) {
        return supportedBcns._bcnAddress.length;
    }

    function getRandomOfTeam(
        string calldata country,
        uint256 amount,
        uint256[] memory tokenIds
    ) external onlyOwner returns (uint256[] memory randomTokenId) {
        uint256[] memory randomNumbers = new uint256[](amount);
        uint256[] memory randomTokenIds = new uint256[](amount);
        uint256 range = tokenIds.length;
        for (uint256 i = 0; i < amount; i++) {
            randomNumbers[i] =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            i,
                            tokenIds.length,
                            block.timestamp,
                            block.difficulty,
                            block.number
                        )
                    )
                ) %
                range;
            randomTokenIds[i] = tokenIds[randomNumbers[i]];
            uint256 lastTokenId = tokenIds[tokenIds.length - i - 1];
            tokenIds[tokenIds.length - i - 1] = tokenIds[randomNumbers[i]];
            tokenIds[randomNumbers[i]] = lastTokenId;
            range--;
        }
        emit RandomTeam(country, randomTokenIds);
        return randomTokenIds;
    }

    function intoChampionBonus() external onlyOwner {
        remainBonus.championBonus =
            remainBonus.championBonus +
            remainBonus.topEightBonus;
        remainBonus.topEightBonus = 0;
        bonus.championBonus = remainBonus.championBonus;
        bonus.topEightBonus = remainBonus.topEightBonus;
    }

    function setDistribution() external virtual override onlyOwner {
        bonus = Bonus({
            ownerBonus: (address(this).balance * 20) / 100,
            championBonus: (address(this).balance * 35) / 100,
            topEightBonus: (address(this).balance * 35) / 100,
            consolationPrize: (address(this).balance * 10) / 100
        });
        remainBonus = RemainBonus({
            ownerBonus: (address(this).balance * 20) / 100,
            championBonus: (address(this).balance * 35) / 100,
            topEightBonus: (address(this).balance * 35) / 100,
            consolationPrize: (address(this).balance * 10) / 100
        });
        claimStatus = true;
    }

    receive() external payable {}

    function claimDistribution(
        uint256[] calldata tokenIds,
        uint8 enumType,
        bytes calldata _signature
    ) external virtual override nonReentrant {
        require(claimStatus, "Not time to claim");
        bytes32 signedHash = 0xfa26db7ca85ead399216e7c6316bc50ed24393c3122b582735e7f3b0f91b93f0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (ownerOf(tokenIds[i]) != msg.sender) {
                require(
                    StakeContract(stakeAddress).stakeOwnerOf(tokenIds[i]) ==
                        msg.sender,
                    "You are not the owner"
                );
            }
            require(
                !bonusInfo[tokenIds[i]][enumType],
                "You have already received the bonus"
            );
            bonusInfo[tokenIds[i]][enumType] = true;
            bonusCliamed[tokenIds[i]] = true;
            signedHash = keccak256(
                abi.encodePacked(signedHash, msg.sender, tokenIds[i], enumType)
            );
        }
        require(
            signedHash.toEthSignedMessageHash().recover(_signature) ==
                ClaimSignAddress,
            "You can't get the consolation prize"
        );

        if (enumType == uint8(ClaimType.ChampionBonus)) {
            uint256 bonusValue = bonus.championBonus / championTokenIdAmount;
            if (remainBonus.championBonus > 0) {
                remainBonus.championBonus =
                    remainBonus.championBonus -
                    (bonusValue * tokenIds.length);
                sendValue(payable(msg.sender), bonusValue * tokenIds.length);
            } else {
                revert("Claim end");
            }
        }

        if (enumType == uint8(ClaimType.TopEightBonus)) {
            uint256 bonusValue = bonus.topEightBonus / topEightRightTeams / 8;
            if (remainBonus.topEightBonus > 0) {
                remainBonus.topEightBonus =
                    remainBonus.topEightBonus -
                    (bonusValue * tokenIds.length);
                sendValue(payable(msg.sender), bonusValue * tokenIds.length);
            } else {
                revert("Claim end");
            }
        }

        if (enumType == uint8(ClaimType.ConsolationPrize)) {
            uint256 bonusValue = bonus.consolationPrize / 24 / 10;
            if (remainBonus.consolationPrize > 0) {
                remainBonus.consolationPrize =
                    remainBonus.consolationPrize -
                    (bonusValue * tokenIds.length);
                sendValue(payable(msg.sender), bonusValue * tokenIds.length);
            } else {
                revert("Claim end");
            }
        }

        emit ClaimEvent(msg.sender, tokenIds, enumType);
    }

    function isSupportClaim(uint256 tokenId)
        external
        view
        virtual
        override
        returns (bool)
    {
        return bonusCliamed[tokenId] == false;
    }

    function isClaimedDistribution(uint256 tokenId)
        external
        view
        virtual
        override
        returns (bool)
    {
        return bonusCliamed[tokenId];
    }

    function isBegainClaim() external view virtual override returns (bool) {
        return claimStatus;
    }

    function setTopEightTeams(uint256 _topEightRightTeams) external onlyOwner {
        topEightRightTeams = _topEightRightTeams;
    }

    function setChampionTokenAmount(uint256 _championTokenAmount)
        external
        onlyOwner
    {
        championTokenIdAmount = _championTokenAmount;
    }

    function setPubSaleTime(uint256 timestamp) external onlyOwner {
        pubSaleTime = timestamp;
    }

    function ownerMint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Sold out!");
        _mint(to, amount);
    }

    function setMintSignedAddress(address _mintSignAddress) external onlyOwner {
        mintSignAddress = _mintSignAddress;
    }

    function setStakeAddress(address _stakeAddress) external onlyOwner {
        stakeAddress = _stakeAddress;
    }

    function setClaimSignedAddress(address _claimSignAddress)
        external
        onlyOwner
    {
        ClaimSignAddress = _claimSignAddress;
    }

    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function setDisapprovedMarketplace(address market, bool isDisapprove)
        external
        onlyOwner
    {
        disapprovedMarketplaces[market] = isDisapprove;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: remainBonus.ownerBonus}("");
        remainBonus.ownerBonus = 0;
        require(success, "Transfer failed.");
    }


    function approve(address to, uint256 tokenId)
        public
        payable
        virtual
        override
    {
        require(!disapprovedMarketplaces[to], "The address is not approved");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            !disapprovedMarketplaces[operator],
            "The address is not approved"
        );
        super.setApprovalForAll(operator, approved);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}