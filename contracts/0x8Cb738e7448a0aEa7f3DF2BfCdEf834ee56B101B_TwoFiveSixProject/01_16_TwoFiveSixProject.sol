// SPDX-License-Identifier: MIT

/* 

 222222222222222    555555555555555555         66666666   
2:::::::::::::::22  5::::::::::::::::5        6::::::6    
2::::::222222:::::2 5::::::::::::::::5       6::::::6     
2222222     2:::::2 5:::::555555555555      6::::::6      
            2:::::2 5:::::5                6::::::6       
            2:::::2 5:::::5               6::::::6        
         2222::::2  5:::::5555555555     6::::::6         
    22222::::::22   5:::::::::::::::5   6::::::::66666    
  22::::::::222     555555555555:::::5 6::::::::::::::66  
 2:::::22222                    5:::::56::::::66666:::::6 
2:::::2                         5:::::56:::::6     6:::::6
2:::::2             5555555     5:::::56:::::6     6:::::6
2:::::2       2222225::::::55555::::::56::::::66666::::::6
2::::::2222222:::::2 55:::::::::::::55  66:::::::::::::66 
2::::::::::::::::::2   55:::::::::55      66:::::::::66   
22222222222222222222     555555555          666666666    

Using this contract? A shout out to @Mint256Art is appreciated!
 */

pragma solidity ^0.8.7;

import "./helpers/OwnableUpgradeable.sol";
import "./helpers/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";

contract TwoFiveSixProject is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    uint256[180] public memberShipFlags;
    uint256[4] public gmTokenFlags;
    string public baseURI;

    bool public memberSaleIsActive;
    bool public gmDaoSaleIsActive;
    bool public publicSaleIsActive;

    uint256 public maxPerTx;
    uint256 public twoFiveSixShare;

    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(address => bool) public projectProxy;
    mapping(address => bool) public addressToRegistryDisabled;

    struct Project {
        string name;
        string symbol;
        address payable artistAddress;
        address payable twoFiveSixFundsAddress;
        address artScriptAddress;
        address royaltyAddress;
        address owner;
        address twoFiveSixGenesisAddress;
        address gmTokenAddress;
        address proxyRegistryAddress;
        uint256 maxSupply;
        uint256 showCaseAmount;
        uint256 memberPrice;
        uint256 publicPrice;
        uint256 royalty;
    }

    Project internal project;

    function initProject(
        Project calldata p,
        uint256 _twoFiveSixShare,
        uint256 _maxPerTx
    ) public initializer {
        __ERC721_init(p.name, p.symbol);
        __Ownable_init(p.owner);
        project = p;
        maxPerTx = _maxPerTx;
        twoFiveSixShare = _twoFiveSixShare;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token not found");
        return
            string(
                abi.encodePacked(baseURI, StringsUpgradeable.toString(_tokenId))
            );
    }

    function showCaseMint(uint256[] calldata the256ArtIds) public onlyOwner {
        uint256 count = the256ArtIds.length;
        uint256 totalSupply = _owners.length;
        require(totalSupply == 0, "Not first mint");
        require(count == project.showCaseAmount, "Must mint all");
        require(project.showCaseAmount % 2 == 0, "Must be even.");

        IERC721Upgradeable twoFiveSix = IERC721Upgradeable(
            project.twoFiveSixGenesisAddress
        );

        for (uint256 i; i < count; i++) {
            require(
                twoFiveSix.ownerOf(the256ArtIds[i]) == _msgSender(),
                "Membership not owned"
            );
            uint256 storedValue = getTokenIdForMembershipId(the256ArtIds[i]);
            bool unset = storedValue == 0;

            require(unset, "Membership already used");
        }

        for (uint256 i; i < (project.showCaseAmount / 2); i++) {
            uint256 tokenId = totalSupply + i;
            uint256 tokenIdTwo = totalSupply + i + (project.showCaseAmount / 2);

            bytes32 hashOne = createHash(tokenId, msg.sender);

            tokenIdToHash[tokenId] = hashOne;
            _setTokenIdForMembershipId(the256ArtIds[i], tokenId);

            _mint(project.artistAddress, tokenId);

            bytes32 hashTwo = createHash(tokenIdTwo, msg.sender);
            tokenIdToHash[tokenIdTwo] = hashTwo;

            _setTokenIdForMembershipId(
                the256ArtIds[i + (project.showCaseAmount / 2)],
                tokenIdTwo
            );

            _mint(project.twoFiveSixFundsAddress, tokenIdTwo);
        }
    }

    function memberMint(uint256[] calldata the256ArtIds, address a)
        public
        payable
    {
        uint256 totalSupply = _owners.length;
        uint256 count = the256ArtIds.length;
        require(memberSaleIsActive, "Member mint not active.");
        require(count > 0, "Mint at least one");
        require(totalSupply + count < project.maxSupply, "Exceeds max supply.");
        require(count < maxPerTx, "Exceeds max per transaction.");
        require(
            count * project.memberPrice <= msg.value,
            "Invalid funds provided."
        );
        require(msg.sender == tx.origin, "No contract minting");

        IERC721Upgradeable twoFiveSix = IERC721Upgradeable(
            project.twoFiveSixGenesisAddress
        );

        for (uint256 i; i < count; i++) {
            require(
                twoFiveSix.ownerOf(the256ArtIds[i]) == _msgSender(),
                "Membership not owned"
            );
            uint256 tokenId = totalSupply + i;

            uint256 storedValue = getTokenIdForMembershipId(the256ArtIds[i]);
            bool unset = (storedValue == 0);

            require(unset, "Membership already used");

            _setTokenIdForMembershipId(the256ArtIds[i], tokenId);

            bytes32 hashOne = createHash(tokenId, msg.sender);
            tokenIdToHash[tokenId] = hashOne;

            _mint(a, tokenId);
        }
    }

    function gmTokenMint(uint256[] calldata gmTokenIds, address a)
        public
        payable
    {
        uint256 totalSupply = _owners.length;
        uint256 count = gmTokenIds.length;
        require(gmDaoSaleIsActive, "GmToken mint not active.");
        require(count > 0, "Mint at least one");
        require(totalSupply + count < project.maxSupply, "Exceeds max supply.");
        require(count < maxPerTx, "Exceeds max per transaction.");
        require(
            count * project.memberPrice <= msg.value,
            "Invalid funds provided."
        );
        require(msg.sender == tx.origin, "No contract minting");

        IERC721Upgradeable gmToken = IERC721Upgradeable(project.gmTokenAddress);

        for (uint256 i; i < count; i++) {
            require(
                gmToken.ownerOf(gmTokenIds[i]) == _msgSender(),
                "GmToken not owned"
            );
            uint256 tokenId = totalSupply + i;

            bool isUsed = getGmTokenUsed(gmTokenIds[i]);

            require(!isUsed, "GmToken already used");

            _setGmTokenUsed(gmTokenIds[i]);

            bytes32 hashOne = createHash(tokenId, msg.sender);
            tokenIdToHash[tokenId] = hashOne;

            _mint(a, tokenId);
        }
    }

    function publicMint(uint256 count, address a) public payable {
        uint256 totalSupply = _owners.length;
        require(publicSaleIsActive, "Public mint not active.");
        require(count > 0, "Mint at least one");
        require(totalSupply + count < project.maxSupply, "Exceeds max supply.");
        require(count < maxPerTx, "Exceeds max per transaction.");
        require(
            count * project.publicPrice <= msg.value,
            "Invalid funds provided."
        );
        require(msg.sender == tx.origin, "No contract minting");

        for (uint256 i; i < count; i++) {
            uint256 tokenId = totalSupply + i;

            bytes32 hashOne = createHash(tokenId, msg.sender);
            tokenIdToHash[tokenId] = hashOne;

            _mint(a, tokenId);
        }
    }

    function createHash(uint256 tokenId, address sender)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    tokenId,
                    sender,
                    blockhash(block.number - 2),
                    blockhash(block.number - 4),
                    blockhash(block.number - 8)
                )
            );
    }

    function getHashFromTokenId(uint256 _id) public view returns (bytes32) {
        return tokenIdToHash[_id];
    }

    function _setTokenIdForMembershipId(uint256 _membershipId, uint256 _tokenId)
        private
    {
        uint256 index = _membershipId / 23;
        uint256 bit = (_membershipId % 23) * 11;

        memberShipFlags[index] =
            (memberShipFlags[index] & ~(0x7FF << bit)) |
            (_tokenId << bit);
    }

    function _setGmTokenUsed(uint256 _gmTokenId) private {
        uint256 index = _gmTokenId / 256;
        uint256 bit = _gmTokenId % 256;

        gmTokenFlags[index] = gmTokenFlags[index] | (1 << bit);
    }

    function getTokenIdForMembershipId(uint256 _membershipId)
        public
        view
        returns (uint256)
    {
        uint256 index = _membershipId / 23;
        uint256 bit = (_membershipId % 23) * 11;
        uint256 storedValue = (memberShipFlags[index] >> bit) & 0x7FF;
        return storedValue;
    }

    function getMembershipIdForTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(_exists(tokenId), "Token not found");

        uint256[]
            memory allTokenIdsForMembershipIds = getAllTokenIdForMembershipId();

        uint256 membershipId;

        for (uint256 i = 1; i < allTokenIdsForMembershipIds.length; i++) {
            if (allTokenIdsForMembershipIds[i] == tokenId) {
                membershipId = i;
                break;
            }
        }
        return membershipId;
    }

    function getGmTokenUsed(uint256 _gmTokenid) public view returns (bool) {
        uint256 index = _gmTokenid / 256;
        uint256 bit = _gmTokenid % 256;
        bool storedValue = ((gmTokenFlags[index] >> bit) & 1) > 0;
        return storedValue;
    }

    function getAllTokenIdForMembershipId()
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory res = new uint256[](4096);
        for (uint256 i = 0; i < 4096; i++) {
            res[i] = getTokenIdForMembershipId(i);
        }
        return res;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress)
        external
        onlyOwner
    {
        project.proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setArtistAddress(address payable _artistAddress)
        external
        onlyOwner
    {
        project.artistAddress = _artistAddress;
    }

    function setTwoFiveSixFundsAddress(address payable _twoFiveSixFundsAddress)
        external
        onlyOwner
    {
        project.twoFiveSixFundsAddress = _twoFiveSixFundsAddress;
    }

    function setRoyalty(uint256 _royalty) external onlyOwner {
        project.royalty = _royalty;
    }

    function setRoyaltyAddress(address payable _royaltyAddress)
        external
        onlyOwner
    {
        project.royaltyAddress = _royaltyAddress;
    }

    function setArtScriptAddress(address _artScriptAddress) external onlyOwner {
        project.artScriptAddress = _artScriptAddress;
    }

    function setTwoFiveSixGenesisAddress(address _twoFiveSixGenesisAddress)
        external
        onlyOwner
    {
        project.twoFiveSixGenesisAddress = _twoFiveSixGenesisAddress;
    }

    function setMemberSaleIsActive(bool isActive) external onlyOwner {
        memberSaleIsActive = isActive;
    }

    function setMemberPrice(uint256 _price) external onlyOwner {
        project.memberPrice = _price;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        project.publicPrice = _price;
    }

    function artScriptAddress() external view returns (address) {
        return project.artScriptAddress;
    }

    function maxSupply() external view returns (uint256) {
        return project.maxSupply;
    }

    function memberPrice() external view returns (uint256) {
        return project.memberPrice;
    }

    function publicPrice() external view returns (uint256) {
        return project.publicPrice;
    }

    function setPublicSaleIsActive(bool isActive) public onlyOwner {
        publicSaleIsActive = isActive;
    }

    function setPresaleIsActive(bool isActive) public onlyOwner {
        memberSaleIsActive = isActive;
        gmDaoSaleIsActive = isActive;
    }

    function setGmDaoSaleIsActive(bool isActive) public onlyOwner {
        gmDaoSaleIsActive = isActive;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        project.twoFiveSixFundsAddress.transfer(
            (balance / 10000) * twoFiveSixShare
        );
        project.artistAddress.transfer(
            (balance / 10000) * (10000 - twoFiveSixShare)
        );
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory data_
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds)
        external
        view
        returns (bool)
    {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account) return false;
        }

        return true;
    }

    function flipProxyState(address proxyAddress) external onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function toggleRegistryAccess() public virtual {
        addressToRegistryDisabled[msg.sender] = !addressToRegistryDisabled[
            msg.sender
        ];
    }

    function isApprovedForAll(address owner, address spender)
        public
        view
        override
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            project.proxyRegistryAddress
        );

        if (
            address(proxyRegistry.proxies(owner)) == spender &&
            !addressToRegistryDisabled[owner]
        ) return true;

        return super.isApprovedForAll(owner, spender);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (project.royaltyAddress, (_salePrice * project.royalty) / 10000);
    }

    function toHex16(bytes16 data) internal pure returns (bytes32 result) {
        result =
            (bytes32(data) &
                0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000) |
            ((bytes32(data) &
                0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >>
                64);
        result =
            (result &
                0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000) |
            ((result &
                0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >>
                32);
        result =
            (result &
                0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000) |
            ((result &
                0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >>
                16);
        result =
            (result &
                0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000) |
            ((result &
                0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >>
                8);
        result =
            ((result &
                0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >>
                4) |
            ((result &
                0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >>
                8);
        result = bytes32(
            0x3030303030303030303030303030303030303030303030303030303030303030 +
                uint256(result) +
                (((uint256(result) +
                    0x0606060606060606060606060606060606060606060606060606060606060606) >>
                    4) &
                    0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) *
                7
        );
    }

    function toHex(bytes32 data) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "0x",
                    toHex16(bytes16(data)),
                    toHex16(bytes16(data << 128))
                )
            );
    }

    function getArtFromChain(uint256 tokenId)
        external
        view
        returns (string memory artwork)
    {
        require(_exists(tokenId), "Token not found");

        uint256 membershipId = getMembershipIdForTokenId(tokenId);

        IArtScript artscript = IArtScript(project.artScriptAddress);

        return
            string(
                abi.encodePacked(
                    "data:text/html;base64,",
                    Base64Upgradeable.encode(
                        abi.encodePacked(
                            "<html><head><script>let inputData={'tokenId': ",
                            StringsUpgradeable.toString(tokenId),
                            ",'membershipId': ",
                            StringsUpgradeable.toString(membershipId),
                            ",'hash': '",
                            toHex(getHashFromTokenId(tokenId)),
                            "'}</script>",
                            artscript.head(),
                            "</head><body><script src='",
                            artscript.externalLibrary(),
                            "'></script>",
                            "<script src='",
                            artscript.twoFiveSixLibrary(),
                            "'></script><script defer>",
                            artscript.artScript(),
                            "</script></body></html>"
                        )
                    )
                )
            );
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

interface IArtScript {
    function projectName() external pure returns (string memory);

    function artistName() external pure returns (string memory);

    function externalLibrary() external pure returns (string memory);

    function twoFiveSixLibrary() external pure returns (string memory);

    function license() external pure returns (string memory);

    function artScript() external pure returns (string memory);

    function head() external pure returns (string memory);
}