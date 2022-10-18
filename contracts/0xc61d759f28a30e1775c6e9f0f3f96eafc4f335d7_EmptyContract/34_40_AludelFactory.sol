// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import {ProxyFactory} from "alchemist/contracts/factory/ProxyFactory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAludel} from "./aludel/IAludel.sol";

contract AludelFactory is Ownable {
    struct ProgramData {
        address template;
        uint64 startTime;
        string name;
        string stakingTokenUrl;
    }
    struct TemplateData {
        bool listed;
        bool disabled;
        string name;
    }

    /// @notice set of template data
    mapping(address => TemplateData) private _templates;

    /// @notice address => ProgramData mapping
    mapping(address => ProgramData) private _programs;

    /// @notice fee's recipient.
    address public feeRecipient;
    /// @notice fee's basis point
    uint16 public feeBps;

    /// @dev emitted when a new template is added
    event TemplateAdded(address template);

    /// @dev emitted when a template is updated
    event TemplateUpdated(address template, bool disabled);

    /// @dev emitted when a program's (deployed via the factory or preexisting)
    // url or name is changed
    event ProgramChanged(address program, string name, string url);
    /// @dev emitted when a program's (deployed via the factory or preexisting)
    /// is created
    event ProgramAdded(address program, string name, string url);
    /// @dev emitted when a program is delisted
    event ProgramDelisted(address program);


    error InvalidTemplate();
    error TemplateNotRegistered();
    error TemplateDisabled();
    error TemplateAlreadyAdded();
    error ProgramAlreadyRegistered();
    error AludelNotRegistered();
    error AludelAlreadyRegistered();


    constructor(address recipient, uint16 bps) {
        feeRecipient = recipient;
        feeBps = bps;
    }

    /// @notice perform a minimal proxy deploy of a predefined aludel template
    /// @param template the number of the template to launch
    /// @param name the string represeting the program's name
    /// @param stakingTokenUrl the program's url
    /// @param data the calldata to use on the new aludel initialization
    /// @return aludel the new aludel deployed address.
    function launch(
        address template,
        string memory name,
        string memory stakingTokenUrl,
        uint64 startTime,
        address vaultFactory,
        address[] memory bonusTokens,
        address ownerAddress,
        bytes calldata data
    )
        public
        returns (address aludel)
    {
        if (!_templates[template].listed) {
            revert TemplateNotRegistered();
        }

        // reverts when template is disabled
        if (_templates[template].disabled) {
            revert TemplateDisabled();
        }

        // create clone and initialize
        aludel = ProxyFactory._create(
            template,
            abi.encodeWithSelector(
                IAludel.initialize.selector,
                startTime,
                ownerAddress,
                feeRecipient,
                feeBps,
                data
            )
        );

        // add program's data to the storage
        _programs[aludel] = ProgramData({
            startTime: startTime,
            template: template,
            name: name,
            stakingTokenUrl: stakingTokenUrl
        });

        // register vault factory
        IAludel(aludel).registerVaultFactory(vaultFactory);

        uint256 bonusTokenLength = bonusTokens.length;

        // register bonus tokens
        for (uint256 index = 0; index < bonusTokenLength; ++index) {
            IAludel(aludel).registerBonusToken(bonusTokens[index]);
        }

        // transfer ownership
        Ownable(aludel).transferOwnership(ownerAddress);
        
        emit ProgramAdded(address(aludel), name, stakingTokenUrl);

        // explicit return
        return aludel;
    }

    /* admin */

    /// @notice adds a new template to the factory
    function addTemplate(address template, string memory name, bool disabled)
        public
        onlyOwner
    {
        // cannot add address(0) as template
        if (template == address(0)) {
            revert InvalidTemplate();
        }

        // add template to the storage
        if (_templates[template].listed) {
            revert TemplateAlreadyAdded();
        } else {
            _templates[template] = TemplateData({
                listed: true,
                disabled: disabled,
                name: name
            });
        }

        // emit event
        emit TemplateAdded(template);
    }

    // @dev function to check if an arbitrary address is a registered program
    // @notice programs cant have a null template, so this should be enough to
    // know if storage is occupied or not
    function isAludel(address who) public view returns(bool){
      return _programs[who].template != address(0);
    }

    /// @notice sets a template as disable or enabled
    function updateTemplate(address template, bool disabled)
        external
        onlyOwner
    {
        if (!_templates[template].listed) {
            revert InvalidTemplate();
        }

        _templates[template].disabled = disabled;
        emit TemplateUpdated(template, disabled);
    }

    /// @notice updates both name and url of a program at once
    /// @dev to set only one of them, you can pass an empty string as the other
    /// and then you'll save some gas
    function updateProgram(address program, string memory newName,string memory newUrl) external onlyOwner {
        // check if the address is already registered
        if(!isAludel(program)){
          revert AludelNotRegistered();
        }
        // update storage
        if(bytes(newName).length != 0){
            _programs[program].name = newName;
        }
        if(bytes(newUrl).length != 0){
            _programs[program].stakingTokenUrl = newUrl;
        }
        // emit event
        emit ProgramChanged(program, newName, newUrl);
    }

    /// @notice manually adds a program
    /// @dev this allows onchain storage of pre-aludel factory programs
    function addProgram(
        address program,
        address template,
        string memory name,
        string memory stakingTokenUrl,
        uint64 startTime
    )
        external
        onlyOwner
    {
        if(isAludel(program)){
          revert AludelAlreadyRegistered();
        }
        if (!_templates[template].listed) {
            revert TemplateNotRegistered();
        }

        // add program's data to the storage
        _programs[program] = ProgramData({
            startTime: startTime,
            template: template,
            name: name,
            stakingTokenUrl: stakingTokenUrl
        });

        emit ProgramAdded(program, name, stakingTokenUrl);

    }

    /// @notice delist a program
    /// @dev removes `program` as a registered instance of the factory
    function delistProgram(address program) external onlyOwner {
        if(!isAludel(program)){
          revert AludelNotRegistered();
        }
        delete _programs[program];

        emit ProgramDelisted(program);
    }

    /// @notice retrieves a template's data
    function getTemplate(address template)
        external
        view
        returns (TemplateData memory)
    {
        return _templates[template];
    }

    // @dev the automatically generated getter doesn't return a struct, but
    // instead a tuple. I didn't research the gas cost implications of this,
    // but it's more readable to access fields by name, so this is used to
    // force returning a struct
    function programs(address program) external view returns (ProgramData memory) {
      return _programs[program];
    }

    function setFeeRecipient(address newRecipient) external onlyOwner {
        feeRecipient = newRecipient;
    }

    function setFeeBps(uint16 bps) external onlyOwner {
        feeBps = bps;
    }
}