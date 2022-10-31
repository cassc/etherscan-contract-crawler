// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../lib/helpers/Errors.sol";
import "../lib/configurations/GenerativeBoilerplateNFTConfiguration.sol";
import "../lib/helpers/Random.sol";
import "../lib/helpers/BoilerplateParam.sol";
import "../lib/helpers/StringUtils.sol";
import "../interfaces/IGenerativeBoilerplateNFT.sol";
import "../interfaces/IGenerativeNFT.sol";
import "../interfaces/IParameterControl.sol";

contract GenerativeBoilerplateNFT is Initializable, ERC721PresetMinterPauserAutoIdUpgradeable, ReentrancyGuardUpgradeable, IERC2981Upgradeable, IGenerativeBoilerplateNFT {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using ClonesUpgradeable for *;
    using SafeMathUpgradeable for uint256;

    // super admin
    address public _admin;
    // parameter control address
    address public _paramsAddress;

    // projectId is tokenID of project nft
    CountersUpgradeable.Counter private _nextProjectId;

    struct ProjectInfo {
        uint256 _fee; // default frees
        address _feeToken;// default is native token
        uint256 _mintMaxSupply; // max supply can be minted on project
        uint256 _mintTotalSupply; // total supply minted on project
        string _script; // script render: 1/ simplescript 2/ ipfs:// protocol
        uint32 _scriptType; // script type: python, js, ....
        address _creator; // creator list for project, using for royalties
        string _customUri; // project info nft view
        string _projectName; // name of project
        bool _clientSeed; // accept seed from client if true -> contract will not verify value
        BoilerplateParam.ParamsOfProject _paramsTemplate; // struct contains list params of project and random seed(registered) in case mint nft from project
        address _minterNFTInfo;// map projectId ->  NFT collection address mint from project
        uint256 _mintNotOwnerProjectMaxSupply; // limit for nminter is not owner of project
        uint256 _mintNotOnwerProjectTotalSupply;
    }

    mapping(uint256 => ProjectInfo) public _projects;

    // map projectId ->  NFT collection address mint from project
    //    mapping(uint256 => address) public  _minterNFTInfos;

    // mapping seed -> project -> owner
    mapping(bytes32 => mapping(uint256 => address)) _seedOwners;

    /// If seed approval is given, then the approved party may claim rights for any
    /// seed.
    // map owner -> operator -> projectId
    mapping(address => mapping(address => uint256)) public _approvalForAllSeeds;

    // mapping seed already minting
    mapping(bytes32 => mapping(uint256 => uint256)) _seedToTokens;

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseUri,
        address admin,
        address paramsAddress
    ) initializer public {
        require(admin != address(0), Errors.INV_ADD);
        require(paramsAddress != address(0), Errors.INV_ADD);
        __ERC721PresetMinterPauserAutoId_init(name, symbol, baseUri);
        _paramsAddress = paramsAddress;
        _admin = admin;
        // set role for admin address
        grantRole(DEFAULT_ADMIN_ROLE, _admin);

        // revoke role for sender
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function changeAdmin(address newAdm, address newParam) external {
        require(msg.sender == _admin && hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) && newAdm != address(0), Errors.ONLY_ADMIN_ALLOWED);

        // change admin
        if (_admin != newAdm) {
            address _previousAdmin = _admin;
            _admin = newAdm;
            grantRole(DEFAULT_ADMIN_ROLE, _admin);
            revokeRole(DEFAULT_ADMIN_ROLE, _previousAdmin);
        }

        // change param
        require(newParam != address(0));
        if (_paramsAddress != newParam) {
            _paramsAddress = newParam;
        }
    }

    // disable old mint
    function mint(address to) public override {}
    // disable pause
    function pause() public override {}
    // disable unpause
    function unpause() public override {}

    function burn(uint256 tokenId) public override {
        super.burn(tokenId);
        _projects[tokenId]._minterNFTInfo = address(0);
    }

    // mint a Project token id
    // to: owner
    // name: name of project
    // maxSupply: max available nft supply which minted from this project
    // uri: metadata of project info
    // fee: fee mint nft from this project
    // feeAdd: currency for mint nft fee
    // paramsTemplate: json format string for render view template
    function mintProject(
        address to,
        string memory projectName,
        uint256 maxSupply,
        uint256 maxNotOwner,
        string memory script,
        uint32 scriptType,
        bool clientSeed,
        string memory uri,
        uint256 fee,
        address feeAdd,
        BoilerplateParam.ParamsOfProject calldata paramsTemplate
    ) external nonReentrant payable returns (uint256) {
        require(bytes(projectName).length > 3, Errors.MISSING_NAME);
        _nextProjectId.increment();
        uint256 currentTokenId = _nextProjectId.current();
        require(!_exists(currentTokenId), Errors.INV_PROJECT);

        IParameterControl _p = IParameterControl(_paramsAddress);
        if (msg.sender != _admin) {
            uint256 operationFee = _p.getUInt256(GenerativeBoilerplateNFTConfiguration.CREATE_PROJECT_FEE);
            if (operationFee > 0) {
                address operationFeeToken = _p.getAddress(GenerativeBoilerplateNFTConfiguration.FEE_TOKEN);
                if (!(operationFeeToken == address(0))) {
                    IERC20Upgradeable tokenERC20 = IERC20Upgradeable(operationFeeToken);
                    // transfer erc-20 token to this contract
                    require(tokenERC20.transferFrom(
                            msg.sender,
                            address(this),
                            operationFee
                        ));
                } else {
                    require(msg.value >= operationFee);
                }
            }
        }


        if (bytes(uri).length > 0) {
            _projects[currentTokenId]._customUri = uri;
        }
        _projects[currentTokenId]._projectName = projectName;
        _projects[currentTokenId]._creator = _admin;
        _projects[currentTokenId]._mintMaxSupply = maxSupply;
        _projects[currentTokenId]._mintNotOwnerProjectMaxSupply = maxNotOwner;
        _projects[currentTokenId]._fee = fee;
        _projects[currentTokenId]._feeToken = feeAdd;
        _projects[currentTokenId]._paramsTemplate = paramsTemplate;
        _projects[currentTokenId]._script = script;
        _projects[currentTokenId]._scriptType = scriptType;
        _projects[currentTokenId]._clientSeed = clientSeed;

        _safeMint(to, currentTokenId);

        // deploy new by clone from template address
        address generativeNFTAdd = ClonesUpgradeable.clone(_p.getAddress(GenerativeBoilerplateNFTConfiguration.GENERATIVE_NFT_TEMPLATE));
        IGenerativeNFT nft = IGenerativeNFT(generativeNFTAdd);
        nft.init(_projects[currentTokenId]._projectName,
            StringUtils.getSlice(1, 3, _projects[currentTokenId]._projectName),
            _admin,
            address(this),
            currentTokenId);
        _projects[currentTokenId]._minterNFTInfo = generativeNFTAdd;

        return currentTokenId;
    }

    function updateProject(uint256 projectId,
        uint256 newFee, address newFeeAddr,
        string memory newURI,
        string memory newScript,
        address newMinterNFTInfo,
        uint256 maxSupply,
        uint256 totalSupply,
        uint256 notOwnerMaxSupply,
        uint256 notOwnerTotalSupply
    ) external {
        require(msg.sender == _projects[projectId]._creator, Errors.ONLY_CREATOR);
        _projects[projectId]._fee = newFee;
        _projects[projectId]._feeToken = newFeeAddr;
        if (bytes(newURI).length > 0) {
            _projects[projectId]._customUri = newURI;
        }
        if (bytes(newScript).length > 0) {
            _projects[projectId]._script = newScript;
        }
        _projects[projectId]._minterNFTInfo = newMinterNFTInfo;
        _projects[projectId]._mintMaxSupply = maxSupply;
        _projects[projectId]._mintTotalSupply = totalSupply;
        _projects[projectId]._mintNotOwnerProjectMaxSupply = notOwnerMaxSupply;
        _projects[projectId]._mintNotOnwerProjectTotalSupply = notOwnerTotalSupply;
    }

    // generateSeeds - random seed from chain in case project require
    // TODO
    /*
    function generateSeeds(uint256 projectId, uint256 amount) external {
        require(!_projects[projectId]._clientSeed && _exists(projectId));
        bytes32 seed;
        bytes32[] memory seeds = new bytes32[](amount);
        for (uint256 i = 0; i < amount; i++) {
            seed = Random.randomSeed(msg.sender, projectId, i);
            require(_seedOwners[seed][projectId] == address(0));
            _seedOwners[seed][projectId] = msg.sender;
            seeds[i] = seed;
        }
        emit GenerateSeeds(msg.sender, projectId, seeds);
    }
    */

    // registerSeed
    // set seed to chain from client
    // TODO
    /*function registerSeed(uint256 projectId, bytes32 seed) external {
        require(_projects[projectId]._clientSeed && _exists(projectId));
        require(_seedOwners[seed][projectId] == address(0x0));
        _seedOwners[seed][projectId] = msg.sender;
    }*/

    // mintBatchUniqueNFT
    // from projectId -> get algo and minting an batch unique nfr on GenerativeNFT contract collection
    // by default, contract should get 5% fee when minter pay for owner of project
    function mintBatchUniqueNFT(MintRequest memory mintBatch) public nonReentrant payable {
        ProjectInfo memory project = _projects[mintBatch._fromProjectId];
        require(project._minterNFTInfo != address(0), Errors.INV_ADD);
        require(mintBatch._paramsBatch.length > 0 && mintBatch._uriBatch.length == mintBatch._paramsBatch.length, Errors.INV_PARAMS);
        require(project._mintMaxSupply == 0 || project._mintTotalSupply + mintBatch._paramsBatch.length <= project._mintMaxSupply, Errors.REACH_MAX);
        if (project._mintNotOwnerProjectMaxSupply > 0) {// not owner of project
            if (msg.sender != ownerOf(mintBatch._fromProjectId)) {
                _projects[mintBatch._fromProjectId]._mintNotOnwerProjectTotalSupply += mintBatch._paramsBatch.length;
                require(_projects[mintBatch._fromProjectId]._mintNotOnwerProjectTotalSupply <= project._mintNotOwnerProjectMaxSupply);
            }
        }
        // get payable
        uint256 _mintFee = project._fee;
        IParameterControl _p = IParameterControl(_paramsAddress);
        if (_mintFee > 0) {// has fee and
            if (ownerOf(mintBatch._fromProjectId) != msg.sender) {// not owner of project -> get payment
                _mintFee *= mintBatch._paramsBatch.length;
                uint256 operationFee = _p.getUInt256(GenerativeBoilerplateNFTConfiguration.MINT_NFT_FEE);
                if (operationFee == 0) {
                    operationFee = 500;
                    // default 5% getting, 95% pay for owner of project
                }
                if (project._feeToken == address(0x0)) {
                    require(msg.value >= _mintFee);

                    // pay for owner project
                    (bool success,) = ownerOf(mintBatch._fromProjectId).call{value : _mintFee - (_mintFee * operationFee / 10000)}("");
                    require(success);
                } else {
                    IERC20Upgradeable tokenERC20 = IERC20Upgradeable(project._feeToken);
                    // transfer all fee erc-20 token to this contract
                    require(tokenERC20.transferFrom(
                            msg.sender,
                            address(this),
                            _mintFee
                        ));

                    // pay for owner project
                    require(tokenERC20.transfer(ownerOf(mintBatch._fromProjectId), _mintFee - (_mintFee * operationFee / 10000)));
                }
            }
        }

        // minting NFT to other collection by minter
        // needing deploy an new one by cloning from GenerativeNFT(ERC-721) template when mint project
        // get generative nft collection template
        IGenerativeNFT nft = IGenerativeNFT(_projects[mintBatch._fromProjectId]._minterNFTInfo);
        for (uint256 i = 0; i < mintBatch._paramsBatch.length; i++) {
            require(_projects[mintBatch._fromProjectId]._paramsTemplate._params.length == mintBatch._paramsBatch[i]._value.length, Errors.INV_PARAMS);

            // verify seed
            bytes32 seed;
            // TODO
            if (!_projects[mintBatch._fromProjectId]._clientSeed) {// seed on chain
                // TODO always gen seed
                mintBatch._paramsBatch[i]._seed = Random.randomSeed(msg.sender, mintBatch._fromProjectId, project._mintTotalSupply + 1);
                seed = mintBatch._paramsBatch[i]._seed;
                _seedOwners[seed][mintBatch._fromProjectId] = msg.sender;
                // owner of seed
                // require(_seedOwners[seed][mintBatch._fromProjectId] == msg.sender, Errors.SEED_INV);

            } else {// seed off-chain
                seed = mintBatch._paramsBatch[i]._seed;
                // require seed still not registerSeeds
                require(_seedOwners[seed][mintBatch._fromProjectId] == address(0));
                _seedOwners[seed][mintBatch._fromProjectId] = msg.sender;
            }
            // seed not already used
            require(_seedToTokens[seed][mintBatch._fromProjectId] == 0, Errors.SEED_INV);

            // check token uri
            string memory uri = mintBatch._uriBatch[i];
            if (bytes(uri).length == 0) {
                // lazy render
                uri = string(
                    abi.encodePacked(
                        _p.get(GenerativeBoilerplateNFTConfiguration.NFT_BASE_URI),
                        StringsUpgradeable.toHexString(uint256(uint160(address(this))), 20),
                        GenerativeBoilerplateNFTConfiguration.SEPERATE_URI,
                        StringsUpgradeable.toString(mintBatch._fromProjectId),
                        GenerativeBoilerplateNFTConfiguration.SEPERATE_URI,
                        StringsUpgradeable.toString(project._mintTotalSupply + 1)
                    )
                );
            }
            nft.mint(mintBatch._mintTo, _admin, uri, mintBatch._paramsBatch[i]);
            // increase total supply minting on project
            project._mintTotalSupply += 1;
            _projects[mintBatch._fromProjectId]._mintTotalSupply = project._mintTotalSupply;
            // marked this seed is already used
            _seedToTokens[seed][mintBatch._fromProjectId] = project._mintTotalSupply;
        }

        emit MintBatchNFT(msg.sender, mintBatch);
    }

    // approveForAllSeeds
    // operator - address
    // projectId - uint256
    // sender approve for operator on a project
    // operator can make a transferring seed of sender
    /*function approveForAllSeeds(address operator, uint256 projectId) external {
        _approvalForAllSeeds[msg.sender][operator] = projectId;
    }*/

    // isApprovedOrOwnerForSeed
    // return approved or not on projectId of operator on seed
    /*function isApprovedOrOwnerForSeed(address operator, bytes32 seed, uint256 projectId) internal view returns (bool){
        return _seedOwners[seed][projectId] == operator || _approvalForAllSeeds[_seedOwners[seed][projectId]][operator] == projectId;
    }*/

    // transferSeed
    // sender can make a transferring seed from -> to on project as ERC-721
    /*function transferSeed(
        address from,
        address to,
        bytes32 seed, uint256 projectId
    ) external {
        require(_seedToTokens[seed][projectId] != 0 &&
        isApprovedOrOwnerForSeed(msg.sender, seed, projectId) &&
        _seedOwners[seed][projectId] != from &&
            to != address(0));
        _seedOwners[seed][projectId] = to;
    }*/

    // ownerOfSeed
    // get owner of seed on projectId
    /*function ownerOfSeed(bytes32 seed, uint256 projectId) public view returns (address) {
        address explicitOwner = _seedOwners[seed][projectId];
        if (explicitOwner == address(0)) {
            return address(bytes20(seed));
        }
        return explicitOwner;
    }*/

    // setCreator
    // func for set new creator on projectId
    // only creator on projectId can make this func
    function setCreator(address _to, uint256 _id) external {
        require(_projects[_id]._creator == msg.sender, Errors.ONLY_CREATOR);
        _projects[_id]._creator = _to;
    }

    function totalSupply() public view override returns (uint256) {
        return _nextProjectId.current();
    }


    function baseTokenURI() virtual public view returns (string memory) {
        return _baseURI();
    }

    // tokenURI
    // return URI data of project
    // base on customUri of project of baseUri of erc-721
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        if (bytes(_projects[_tokenId]._customUri).length > 0) {
            return _projects[_tokenId]._customUri;
        } else {
            return string(abi.encodePacked(baseTokenURI(), StringsUpgradeable.toString(_tokenId)));
        }
    }

    function exists(
        uint256 _id
    ) external view returns (bool) {
        return _exists(_id);
    }

    /** @dev EIP2981 royalties implementation. */
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
        bool isValue;
    }

    mapping(uint256 => RoyaltyInfo) public royalties;

    function setTokenRoyalty(
        uint256 _tokenId,
        address _recipient,
        uint256 _value
    ) external {
        require(_msgSender() == _admin, Errors.ONLY_ADMIN_ALLOWED);
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), Errors.ONLY_ADMIN_ALLOWED);
        require(_value <= 10000, Errors.REACH_MAX);
        royalties[_tokenId] = RoyaltyInfo(_recipient, uint24(_value), true);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalty = royalties[_tokenId];
        if (royalty.isValue) {
            receiver = royalty.recipient;
            royaltyAmount = (_salePrice * royalty.amount) / 10000;
        } else {
            receiver = _projects[_tokenId]._creator;
            royaltyAmount = (_salePrice * 500) / 10000;
        }
    }

    // withdraw
    // only Admin can withdraw operation fee on this contract
    // receiver: receiver address
    // erc20Addr: currency address
    // amount: amount
    function withdraw(address receiver, address erc20Addr, uint256 amount) external nonReentrant {
        require(_msgSender() == _admin, Errors.ONLY_ADMIN_ALLOWED);
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), Errors.ONLY_ADMIN_ALLOWED);
        bool success;
        if (erc20Addr == address(0x0)) {
            require(address(this).balance >= amount);
            (success,) = receiver.call{value : amount}("");
            require(success);
        } else {
            IERC20Upgradeable tokenERC20 = IERC20Upgradeable(erc20Addr);
            // transfer erc-20 token
            require(tokenERC20.transfer(receiver, amount));
        }
    }

    function getParamsTemplate(uint256 id) external view returns (BoilerplateParam.ParamsOfProject memory) {
        return _projects[id]._paramsTemplate;
    }
}