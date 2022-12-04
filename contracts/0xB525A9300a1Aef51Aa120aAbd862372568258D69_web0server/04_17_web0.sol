//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./lib/Rando.sol";
import "./lib/Esc.sol";
import "base64-sol/base64.sol";



////////////////////////////////////////////
//
// web0
// 200 OK :)
//
////////////////////////////////////////////


contract web0 is ERC721A, ERC721AQueryable, ReentrancyGuard {
    
    uint public constant MAX_SLOTS = 100;

    mapping(uint => string) private _titles;
    mapping(uint => address) private _page_templates;
    address private _default_template;
    uint private _ids;

    // Externals
    web0plugins public immutable plugins;

    /// EVENTS
    event pageCreated(uint indexed id, address indexed creator, string title);

    /// CHECKS
    modifier onlyOwner() {
        require(owner() == msg.sender, 'ONLY_OWNER');
        _;
    }

    function _reqOnlyHolder(uint page_id_) private view {
        require(ownerOf(page_id_) == msg.sender, 'ONLY_HOLDER');
    }


    //////////////////////////
    // CONTRACT
    //////////////////////////


    constructor(address template_) ERC721A("web0", "WEB0"){

        _default_template = template_;
        plugins = new web0plugins();

        string[] memory titles_ = new string[](1);
        titles_[0] = 'Hello world!';
        _createPagesFor(msg.sender,  titles_);

    }


    function owner() public view returns(address){
        if(_exists(0)){
            return ownerOf(0);
        } else {
            return address(0);
        }
    }


    function _startTokenId() internal pure override returns(uint){
        return 0;
    }


    //////////////////////////
    // TEMPLATES
    //////////////////////////
    

    /// @notice get a specific page's web0template template address
    function getPageTemplate(uint page_id_) public view returns(address) {
        address template_ = _page_templates[page_id_];
        if(template_ == address(0))
            return _default_template;
        return template_;
    }

    /// @notice get a specific page's web0template template contract
    function getWeb0template(uint page_id_) public view returns(web0template){
        return web0template(getPageTemplate(page_id_));
    }

    /// @notice let holders of a page set the web0template template version
    function setPageTemplate(uint page_id_, address template_) public {
        _reqOnlyHolder(page_id_);
        _page_templates[page_id_] = template_;
    }

    /// @notice let holders of a page set the web0template template version
    function previewPageTemplate(uint page_id_, address template_, bool encode_) public view returns(string memory) {
        return web0template(template_).html(page_id_, encode_, address(this));
    }



    //////////////////////////
    // PAGES
    //////////////////////////

    /// @notice create a new page with a given title
    function createPages(string[] memory titles_) public payable nonReentrant returns(uint) {
        _createPagesFor(msg.sender, titles_);
    }

    /// @notice let holders set a given page's title
    function setPageTitle(uint page_id_, string memory title_) public {
        _reqOnlyHolder(page_id_);
        _titles[page_id_] = title_;
    }

    /// @notice outputs the title of page_id_
    function getPageTitle(uint page_id_) public view returns(string memory){
        return _titles[page_id_];
    }

    /// @notice return total number of pages created
    function getPageCount() public view returns(uint){
        return _totalMinted();
    }

    /// @dev internal function to create a page for a given address
    function _createPagesFor(address for_, string[] memory titles_) private returns(uint){
                
        uint id_ = _totalMinted();
        _safeMint(for_, titles_.length);
        
        uint i = 0;
        while(i < titles_.length){
            
            _titles[id_] = titles_[i];
            emit pageCreated(id_, for_, titles_[i]);

            ++i;
            ++id_;

        }

        return id_;

    }



    
    //////////////////////////
    // RENDER
    //////////////////////////

    /// @notice outputs the html of page_id_
    function html(uint page_id_, bool encode_) public view returns(string memory){
        return getWeb0template(page_id_).html(page_id_, encode_, address(this));
    }
    


    //////////////////////////
    // TOKEN
    //////////////////////////

    function tokenURI(uint page_id_) public view override returns(string memory){
        require(_exists(page_id_), 'PAGE_DOES_NOT_EXIST');
        return getWeb0template(page_id_).json(page_id_, true, address(this));
    }


}






////////////////////////////////////////////
//
// web0template base contract
//
////////////////////////////////////////////

abstract contract web0template {

    function previewHtml(uint page_id_, web0plugins.PluginInput[] memory preview_plugins_, bool encode_, address web0_) public virtual view returns(string memory);
    function html(uint page_id_, bool encode_, address web0_) public virtual view returns(string memory html_);
    function json(uint page_id_, bool encode_, address web0_) public virtual view returns(string memory json_);

}



////////////////////////////////////////////
//
// web0external base contract
//
////////////////////////////////////////////

abstract contract web0external {

    web0 _parent;

    constructor(address parent_){
        _parent = web0(parent_);
    }

    modifier isParent(address caller_){
        require(caller_ == address(_parent), 'NOT_PARENT');
        _;
    }

    modifier onlyHolder(uint page_id_){
        require(_parent.ownerOf(page_id_) == msg.sender, 'ONLY_HOLDER');
        _;
    }


}













////////////////////////////////////////////
//
// web0plugin base contract
//
////////////////////////////////////////////

abstract contract web0plugin {

    struct Param {
        string _string;
        uint _uint;
        address _address;
        bool _bool;
    }

    struct ParamInfo {
        string param_type;
        string param_description;
    }

    struct Info {
        string name;
        ParamInfo[] params;
    }

    modifier paramsCount(Param[] memory params_, uint length_){
        require(params_.length == length_, 'UNMATCHED_PARAMS');
        _;
    }

    modifier noDoubleInstall(uint page_id_){
        require(!web0plugins(msg.sender).isInstalled(page_id_, address(this)), string(abi.encodePacked('NO_DOUBLE_INSTALL: ', info().name)));
        _;
    }

    function info() public virtual view returns(Info memory);
    function head(uint page_id_, Param[] memory params_, bool preview_, address web0_) public virtual view returns(string memory){ return ''; }
    function body(uint page_id_, Param[] memory params_, bool preview_, address web0_) public virtual view returns(string memory){ return ''; }
    function install(uint page_id_, Param[] memory params_, address web0_) public virtual returns(bool){ return true; }
    function uninstall(uint page_id_, Param[] memory params_, address web0_) public virtual returns(bool) { return true; }

}



contract web0plugins is web0external, ReentrancyGuard {


    struct Plugin {
        string name;
        address location;
        uint slot;
        web0plugin.Param[] params;
    }

    struct PluginInput {
        address location;
        uint slot;
        web0plugin.Param[] params;
    }

    constructor() web0external(msg.sender) {

    }

    mapping(uint => mapping(uint => Plugin)) private _plugins;
    mapping(uint => uint) private _plugins_count;


    function _reqSlotUsed(uint page_id_, uint slot_) private view {
        require(_slotUsed(page_id_, slot_), 'SLOT_USED');
    }



    //////////////////////////
    // PLUGINS
    //////////////////////////


    /// @notice batch install plugins
    function install(uint page_id_, PluginInput[] memory plugins_) public onlyHolder(page_id_) {

        for (uint i = 0; i < plugins_.length; i++) {
            _install(page_id_, plugins_[i].location, plugins_[i].slot, plugins_[i].params);
        }

    }

    /// @notice preview the html output of given plugin
    function preview(uint page_id_, PluginInput[] memory preview_, bool encode_) public view returns(string memory html_){
        return _parent.getWeb0template(page_id_).previewHtml(page_id_, preview_, encode_, address(_parent));
    }

    /// @dev internal method to install a given plugin
    function _install(uint page_id_, address address_, uint slot_, web0plugin.Param[] memory params_) private {
        
        web0plugin plugin_ = web0plugin(address_);

        bool installed = plugin_.install(page_id_, params_, address(this));

        if(installed){
            
            web0plugin.Info memory pluginfo_ = plugin_.info();

            _plugins[page_id_][slot_].name = pluginfo_.name;
            _plugins[page_id_][slot_].location = address_;
            _plugins[page_id_][slot_].slot = slot_;
            
            uint i;
            while(i < pluginfo_.params.length){
                _plugins[page_id_][slot_].params.push(web0plugin.Param('', 0, address(0), false));
                ++i;
            }

            _plugins[page_id_][slot_].params;
            if(params_.length > 0)
                _setParams(page_id_, slot_, params_);
            _plugins_count[page_id_]++;

        }

    }

    /// @notice batch uninstall plugins
    function uninstall(uint page_id_, uint[] memory slots_) public onlyHolder(page_id_) nonReentrant {

        for(uint i = 0; i < slots_.length; i++){
            if(_slotUsed(page_id_, slots_[i])){
                _uninstall(page_id_, slots_[i]);
            }
        }

    }

    /// @dev internal method to uninstall the plugin in a given slot
    function _uninstall(uint page_id_, uint slot_) private {
        
        Plugin memory plugin_ = _plugins[page_id_][slot_];
        
        bool uninstalled = web0plugin(plugin_.location).uninstall(page_id_, plugin_.params, address(this));

        if(uninstalled){
            delete _plugins[page_id_][slot_];
            _plugins_count[page_id_]--;
        }

    }

    /// @notice list all the plugins in use for a given page_id ordered by their slot number
    function list(uint page_id_) public view returns(Plugin[] memory){
        
        uint slot_ = 1;
        uint i = 0;
        Plugin[] memory plugins_ = new Plugin[](_plugins_count[page_id_]);
        while(slot_ <= _parent.MAX_SLOTS()){
            if(_slotUsed(page_id_, slot_)){
                plugins_[i] = _plugins[page_id_][slot_];
                ++i;
            }
            ++slot_;
        }
        
        return plugins_;

    }

    /// @notice create a json array of installed plugins
    /// @dev this is used to create the json array of installed plugins for the web0template
    function json(uint page_id_) public view returns(string memory){
        
        uint slot_ = 1;
        uint i = 0;
        string memory json_ = '[';
        while(slot_ <= _parent.MAX_SLOTS()){
            if(_slotUsed(page_id_, slot_)){
                json_ = string(abi.encodePacked(json_, i > 0 ? ',' : '', _json(page_id_, slot_)));
                ++i;
            }
            ++slot_;
        }
        json_ = string(abi.encodePacked(json_, ']'));
        return json_;

    }


    function _json(uint page_id, uint slot) private view returns(string memory){
        
        Plugin memory plugin_ = _plugins[page_id][slot];
        string memory json_ = string(abi.encodePacked('{', '"name":"', plugin_.name, '", "location":"', Strings.toHexString(uint160(plugin_.location), 20), '", "slot":', Strings.toString(plugin_.slot),'}'));
        return json_;

    }

    /// @notice output number of plugins used for a given page_id
    function count(uint page_id_) public view returns(uint count_){
        
        uint slot_ = 1;
        while(slot_ <= _parent.MAX_SLOTS()){
            if(_slotUsed(page_id_, slot_)){
                ++count_;
            }
            ++slot_;
        }
        
        return count_;

    }

    /// @notice check if a plugin is installed for a given page_id
    function isInstalled(uint page_id_, address address_) public view returns(bool){

        uint slot_ = 1;
        while(slot_ <= _parent.MAX_SLOTS()){
            if(_plugins[page_id_][slot_].location == address_)
                return true;
            ++slot_;
        }

        return false;

    }

    /// @notice set the parameters for plugin in slot_ of page_id_
    function setParams(uint page_id_, uint slot_, web0plugin.Param[] memory params_) public onlyHolder(page_id_) {
        _reqSlotUsed(page_id_, slot_);
        _setParams(page_id_, slot_, params_);
    }

    /// @dev internal function to set params
    function _setParams(uint page_id_, uint slot_, web0plugin.Param[] memory params_) private {      
        for(uint i = 0; i < params_.length; i++){
            _plugins[page_id_][slot_].params[i] = params_[i];
        }
    }
    
    /// @notice get the parameters for the plugin in slot_ of page_id_
    function getParams(uint page_id_, uint slot_) public view returns(web0plugin.Param[] memory) {
        _reqSlotUsed(page_id_, slot_);
        return _plugins[page_id_][slot_].params;
    }

    /// @dev internal method to check if the slot_ of page_id_ is empty
    function _slotEmpty(uint page_id_, uint slot_) private view returns(bool){
        return (_plugins[page_id_][slot_].location == address(0));
    }

    /// @dev internal method to check if the slot_ of page_id_ is in use
    function _slotUsed(uint page_id_, uint slot_) private view returns(bool){
        return !_slotEmpty(page_id_, slot_);
    }



}