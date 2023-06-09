// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

         `````                 `````                                                                                                                  
        /NNNNN.               /NNNNN`                                                                                                                 
        /MMMMM.               +MMMMM`                                                                                                                 
        :hhhhh/::::.     -::::sMMMMM`         ``````      ``````````       `...`        ```````     `         `  ````````          ```                
         `````mNNNNs     NNMNFTMMMMM`       ``bddddd.`    mmdddddddd``  .odhyyhdd+`  ``sddddddd/`  gm-       gm/ dmhhhhhhdh+`    `/dddo`              
              mMMMMy     NMMMMMMMMMM`     ``bd-.....bd-`  MM........mm `mM:`` `.oMy  sm/.......sd: gM-       gM+ NM-`````.sMy  `/do...+do`            
              oWAGMI+++++GMMMMMMMMMM`     gm:.      ..gm. MM        MM `NM:.     /:  yM/       `.` gM-       gM+ NM`      :Md /ms.`   `.+mo           
                   /MMMMM`    +MMMMM`     GM.         gM- GMdddddddd:-  -ydhhhs+:.   yM/           gM-       gM+ NM+////+smh. +Ms       +Ms           
                   /MMMMM`    +MMMMM`     GM.         gM- MM::::::::hh    `.-:/ohmh. yM/           gM-       gM+ NMsoooooyNy` +MdsssssssGMs           
              yMMMMs:::::yMMMMMMMMMM`     yh/:      -:yh. MM        MM /h/       sMs yM/       .:` gM/       gM/ NM`      sM+ +Md+++++++GMs           
              gMMMMs     M.OBSCURA.M`       yh/:::::yh.   MM::::::::hh .gM+..``.:CR: oh+:::::::sh: :Nm/.``..oMh` NM`      :My +Ms       +Ms .:.       
         `````mNNNNs     MMMMM'21'MM`         ahhhhh`     hhhhhhhhhh`   `/ydhhhhho.    ohhhhhhh:    .+hdhhhdy/`  hh`      `hy`/h+       /h+ :h+       
        /mmmmm-....`     .....gMMMMM`                                        ``                         ```                                           
        /MMMMM.               +MMMMM`                                                                                                                 
        :mmmmm`               /mmmmm`                                                                                                                 

*/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ObscuraCurated is ERC721Enumerable, AccessControlEnumerable, IERC2981 {
    using Strings for uint256;

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    uint256 private constant DIVIDER = 10**5;
    uint256 private nextProjectId;
    uint256 private defaultRoyalty;
    address private _obscuraAddress;
    string private _contractURI;
    string private _defaultPendingCID;

    mapping(uint256 => string) public tokenIdToCID;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => uint256) public tokenIdToProject;

    struct Project {
        uint256 maxTokens;
        uint256 circulatingPublic;
        uint256 circulatingReserved;
        uint256 platformReserveAmount;
        uint256 royalty;
        bool active;
        string artist;
        string cid;
    }

    event ProjectCreatedEvent(address caller, uint256 indexed projectId);

    event SetProjectCIDEvent(
        address caller,
        uint256 indexed projectId,
        string cid
    );

    event SetTokenCIDEvent(address caller, uint256 tokenId, string cid);

    event SetSalePublicEvent(
        address caller,
        uint256 indexed projectId,
        bool isSalePublic
    );

    event ProjectMintedEvent(
        address user,
        uint256 indexed projectId,
        uint256 tokenId
    );

    event ProjectMintedByTokenEvent(
        address user,
        uint256 indexed projectId,
        uint256 tokenId
    );

    event ObscuraAddressChanged(address oldAddress, address newAddress);

    event WithdrawEvent(address caller, uint256 balance);

    constructor(address admin, address payable obscuraAddress)
        ERC721("Obscura Curated", "OC")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _obscuraAddress = obscuraAddress;
        defaultRoyalty = 10;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Token doesn't exist");
        uint256 projectId = tokenIdToProject[tokenId];
        uint256 _royaltyAmount = (salePrice * projects[projectId].royalty) /
            100;

        return (_obscuraAddress, _royaltyAmount);
    }

    function setDefaultRoyalty(uint256 royaltyPercent)
        public
        onlyRole(MODERATOR_ROLE)
    {
        defaultRoyalty = royaltyPercent;
    }

    function setProjectRoyalty(uint256 projectId, uint256 royaltyPercent)
        public
        onlyRole(MODERATOR_ROLE)
    {
        projects[projectId].royalty = royaltyPercent;
    }

    function setContractURI(string memory contractURI_)
        external
        onlyRole(MODERATOR_ROLE)
    {
        _contractURI = contractURI_;
    }

    function setProjectCID(uint256 projectId, string calldata cid)
        external
        onlyRole(MODERATOR_ROLE)
    {
        projects[projectId].cid = cid;

        emit SetProjectCIDEvent(msg.sender, projectId, cid);
    }

    function setTokenCID(uint256 tokenId, string calldata cid)
        external
        onlyRole(MODERATOR_ROLE)
    {
        tokenIdToCID[tokenId] = cid;

        emit SetTokenCIDEvent(msg.sender, tokenId, cid);
    }

    function setDefaultPendingCID(string calldata defaultPendingCID)
        external
        onlyRole(MODERATOR_ROLE)
    {
        _defaultPendingCID = defaultPendingCID;
    }

    function setSalePublic(uint256 projectId, bool _isSalePublic)
        external
        onlyRole(MODERATOR_ROLE)
    {
        projects[projectId].active = _isSalePublic;

        emit SetSalePublicEvent(msg.sender, projectId, _isSalePublic);
    }

    function setObscuraAddress(address newObscuraAddress)
        external
        onlyRole(MODERATOR_ROLE)
    {
        _obscuraAddress = payable(newObscuraAddress);
        emit ObscuraAddressChanged(_obscuraAddress, newObscuraAddress);
    }

    function createProject(
        string memory artist,
        uint256 maxTokens,
        uint256 platformReserveAmount,
        string memory cid
    ) external onlyRole(MODERATOR_ROLE) {
        require(maxTokens < DIVIDER, "Cannot exceed 100,000");
        require(bytes(artist).length > 0, "Artist name missing");
        require(
            platformReserveAmount < maxTokens,
            "Platform reserve too high."
        );

        uint256 projectId = nextProjectId += 1;

        projects[projectId] = Project({
            artist: artist,
            maxTokens: maxTokens,
            circulatingPublic: 0,
            circulatingReserved: 0,
            platformReserveAmount: platformReserveAmount,
            active: false,
            cid: cid,
            royalty: defaultRoyalty
        });

        emit ProjectCreatedEvent(msg.sender, projectId);
    }

    function mintToBySelect(
        address to,
        uint256 projectId,
        uint256 tokenId
    ) external onlyRole(MINTER_ROLE) {
        Project memory project = projects[projectId];
        uint256 circulatingPublic = projects[projectId].circulatingPublic += 1;
        require(project.maxTokens > 0, "Project doesn't exist");
        require(tokenId > 0, "Token ID cannot be 0.");
        require(tokenId <= project.maxTokens, "Token ID doesn't exist");
        require(project.active == true, "Public sale is not open");
        require(
            circulatingPublic <=
                project.maxTokens - project.platformReserveAmount,
            "All public tokens have been minted"
        );

        uint256 _tokenId = (projectId * DIVIDER) + (tokenId);
        tokenIdToProject[_tokenId] = projectId;
        _mint(to, _tokenId);

        emit ProjectMintedByTokenEvent(to, projectId, tokenId);
    }

    function mintPlatformReserveBySelect(
        address to,
        uint256 projectId,
        uint256 tokenId
    ) external onlyRole(MINTER_ROLE) {
        Project memory project = projects[projectId];

        uint256 circulatingReserved = projects[projectId]
            .circulatingReserved += 1;

        require(
            circulatingReserved <= project.platformReserveAmount,
            "Platform reserve already minted"
        );
        require(project.maxTokens > 0, "Project doesn't exist");
        require(tokenId > 0, "Token ID cannot be 0.");
        require(tokenId <= project.maxTokens, "Token ID doesn't exist");
        require(project.active == true, "Public sale is not open");

        uint256 _tokenId = (projectId * DIVIDER) + (tokenId);
        tokenIdToProject[_tokenId] = projectId;
        _mint(to, _tokenId);

        emit ProjectMintedByTokenEvent(to, projectId, tokenId);
    }

    function mintTo(
        address to,
        uint256 projectId,
        uint256 tokenId
    ) external onlyRole(MINTER_ROLE) {
        tokenIdToProject[tokenId] = projectId;
        _mint(to, tokenId);

        emit ProjectMintedEvent(to, projectId, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory tokenCID = tokenIdToCID[tokenId];

        if (bytes(tokenCID).length > 0) {
            return string(abi.encodePacked("https://arweave.net/", tokenCID));
        }

        uint256 projectId = tokenIdToProject[tokenId];
        string memory projectCID = projects[projectId].cid;

        if (bytes(projectCID).length > 0) {
            return
                string(
                    abi.encodePacked(
                        "https://arweave.net/",
                        projectCID,
                        "/",
                        tokenId.toString()
                    )
                );
        }

        return
            string(
                abi.encodePacked("https://arweave.net/", _defaultPendingCID)
            );
    }

    function isSalePublic(uint256 projectId)
        external
        view
        returns (bool active)
    {
        return projects[projectId].active;
    }

    function getProjectMaxPublic(uint256 projectId)
        external
        view
        returns (uint256 maxTokens)
    {
        return
            projects[projectId].maxTokens -
            projects[projectId].platformReserveAmount;
    }

    function getProjectCirculatingPublic(uint256 projectId)
        external
        view
        returns (uint256 maxTokens)
    {
        return
            projects[projectId].circulatingPublic -
            projects[projectId].platformReserveAmount;
    }

    function getProjectPlatformReserve(uint256 projectId)
        external
        view
        returns (uint256 platformReserveAmount)
    {
        return projects[projectId].platformReserveAmount;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}