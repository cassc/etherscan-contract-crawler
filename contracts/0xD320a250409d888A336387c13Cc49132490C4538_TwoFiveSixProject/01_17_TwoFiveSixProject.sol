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

pragma solidity ^0.8.13;

import "./helpers/OwnableUpgradeable.sol";
import "./helpers/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";

contract TwoFiveSixProject is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    uint256[180] public memberShipFlags;
    uint256[4] public gmTokenFlags;
    uint256[4] public grailersTokenFlags;
    string public baseURI;

    address public twoFiveSixGenesisAddress;
    address public gmTokenAddress;
    address public grailersAddress;

    uint256 public maxPerTx;
    uint256 public twoFiveSixShare;

    mapping(uint256 => bytes32) public tokenIdToHash;

    struct Project {
        string name;
        address payable artistAddress;
        address payable twoFiveSixFundsAddress;
        address artScriptAddress;
        address royaltyAddress;
        address owner;
        uint256 maxSupply;
        uint256 showCaseAmount;
        uint256 memberPrice;
        uint256 publicPrice;
        uint256 royalty;
        uint256 preSaleTimeStamp;
        uint256 publicTimetamp;
        bool memberOnly;
    }

    Project private project;

    function initProject(
        Project calldata p,
        uint256 _twoFiveSixShare,
        uint256 _maxPerTx,
        address _twoFiveSixGenesisAddress,
        address _gmTokenAddress,
        address _grailersAddress,
        string calldata _baseOfBase
    ) public initializer {
        __ERC721_init(p.name, "256ART");
        __Ownable_init(p.owner);
        project = p;
        maxPerTx = _maxPerTx;
        twoFiveSixShare = _twoFiveSixShare;
        grailersAddress = _grailersAddress;
        gmTokenAddress = _gmTokenAddress;
        twoFiveSixGenesisAddress = _twoFiveSixGenesisAddress;
        baseURI = string(
            abi.encodePacked(
                _baseOfBase,
                _toLower(StringsUpgradeable.toHexString(address(this))),
                "/json_files/"
            )
        );
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
            twoFiveSixGenesisAddress
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
        require(project.preSaleTimeStamp < block.timestamp, "Sale not active");
        require(count > 0, "Mint at least one");
        require(totalSupply + count < project.maxSupply, "Exceeds max supply.");
        require(count < maxPerTx, "Exceeds max per transaction.");
        require(
            count * project.memberPrice <= msg.value,
            "Invalid funds provided."
        );
        require(msg.sender == tx.origin, "No contract minting");

        IERC721Upgradeable twoFiveSix = IERC721Upgradeable(
            twoFiveSixGenesisAddress
        );

        for (uint256 i; i < count; i++) {
            require(
                twoFiveSix.ownerOf(the256ArtIds[i]) == a,
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
        require(project.preSaleTimeStamp < block.timestamp, "Sale not active");
        require(!project.memberOnly, "Only members can mint.");
        require(count > 0, "Mint at least one");
        require(totalSupply + count < project.maxSupply, "Exceeds max supply.");
        require(count < maxPerTx, "Exceeds max per transaction.");
        require(
            count * project.memberPrice <= msg.value,
            "Invalid funds provided."
        );
        require(msg.sender == tx.origin, "No contract minting");

        IERC721Upgradeable gmToken = IERC721Upgradeable(gmTokenAddress);

        for (uint256 i; i < count; i++) {
            require(gmToken.ownerOf(gmTokenIds[i]) == a, "GmToken not owned");
            uint256 tokenId = totalSupply + i;

            bool isUsed = getGmTokenUsed(gmTokenIds[i]);

            require(!isUsed, "GmToken already used");

            _setGmTokenUsed(gmTokenIds[i]);

            bytes32 hashOne = createHash(tokenId, msg.sender);
            tokenIdToHash[tokenId] = hashOne;

            _mint(a, tokenId);
        }
    }

    function grailersTokenMint(uint256[] calldata grailersTokenIds, address a)
        public
        payable
    {
        uint256 totalSupply = _owners.length;
        uint256 count = grailersTokenIds.length;
        require(project.preSaleTimeStamp < block.timestamp, "Sale not active");
        require(!project.memberOnly, "Only members can mint.");
        require(count > 0, "Mint at least one");
        require(totalSupply + count < project.maxSupply, "Exceeds max supply.");
        require(count < maxPerTx, "Exceeds max per transaction.");
        require(
            count * project.memberPrice <= msg.value,
            "Invalid funds provided."
        );
        require(msg.sender == tx.origin, "No contract minting");

        IERC721Upgradeable grailersToken = IERC721Upgradeable(gmTokenAddress);

        for (uint256 i; i < count; i++) {
            require(
                grailersToken.ownerOf(grailersTokenIds[i]) == a,
                "GrailersToken not owned"
            );
            uint256 tokenId = totalSupply + i;

            bool isUsed = getGrailersTokenUsed(grailersTokenIds[i]);

            require(!isUsed, "GrailersToken already used");

            _setGrailersTokenUsed(grailersTokenIds[i]);

            bytes32 hashOne = createHash(tokenId, msg.sender);
            tokenIdToHash[tokenId] = hashOne;

            _mint(a, tokenId);
        }
    }

    function publicMint(uint256 count, address a) public payable {
        uint256 totalSupply = _owners.length;
        require(project.publicTimetamp < block.timestamp, "Sale not active");
        require(!project.memberOnly, "Only members can mint.");
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

    function _setGrailersTokenUsed(uint256 _grailersTokenId) private {
        uint256 index = _grailersTokenId / 256;
        uint256 bit = _grailersTokenId % 256;

        grailersTokenFlags[index] = grailersTokenFlags[index] | (1 << bit);
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

    function getGrailersTokenUsed(uint256 _grailersTokenid)
        public
        view
        returns (bool)
    {
        uint256 index = _grailersTokenid / 256;
        uint256 bit = _grailersTokenid % 256;
        bool storedValue = ((grailersTokenFlags[index] >> bit) & 1) > 0;
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
        twoFiveSixGenesisAddress = _twoFiveSixGenesisAddress;
    }

    function setMemberPrice(uint256 _price) external onlyOwner {
        project.memberPrice = _price;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        project.publicPrice = _price;
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

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
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

    //convenience project getters
    // Getter function for the name field of a private Project struct
    function projectName() external view returns (string memory) {
        return project.name;
    }

    // Getter function for the artistAddress field of a private Project struct
    function artistAddress() external view returns (address payable) {
        return project.artistAddress;
    }

    // Getter function for the twoFiveSixFundsAddress field of a private Project struct
    function twoFiveSixFundsAddress() external view returns (address payable) {
        return project.twoFiveSixFundsAddress;
    }

    // Getter function for the artScriptAddress field of a private Project struct
    function artScriptAddress() external view returns (address) {
        return project.artScriptAddress;
    }

    // Getter function for the royaltyAddress field of a private Project struct
    function royaltyAddress() external view returns (address) {
        return project.royaltyAddress;
    }

    // Getter function for the maxSupply field of a private Project struct
    function maxSupply() external view returns (uint256) {
        return project.maxSupply;
    }

    // Getter function for the showCaseAmount field of a private Project struct
    function showCaseAmount() external view returns (uint256) {
        return project.showCaseAmount;
    }

    // Getter function for the memberPrice field of a private Project struct
    function memberPrice() external view returns (uint256) {
        return project.memberPrice;
    }

    // Getter function for the publicPrice field of a private Project struct
    function publicPrice() external view returns (uint256) {
        return project.publicPrice;
    }

    // Getter function for the royalty field of a private Project struct
    function royalty() external view returns (uint256) {
        return project.royalty;
    }

    // Getter function for the preSaleTimeStamp field of a private Project struct
    function preSaleTimeStamp() external view returns (uint256) {
        return project.preSaleTimeStamp;
    }

    // Getter function for the publicTimetamp field of a private Project struct
    function publicTimetamp() external view returns (uint256) {
        return project.publicTimetamp;
    }

    // Getter function for the memberOnly field of a private Project struct
    function memberOnly() external view returns (bool) {
        return project.memberOnly;
    }
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