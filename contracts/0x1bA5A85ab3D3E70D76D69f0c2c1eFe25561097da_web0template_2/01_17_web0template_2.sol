//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "./../web0.sol";
import "./../lib/Esc.sol";
import "./../lib/Rando.sol";


//////////////////////
//
// web0template v2
//
//////////////////////

contract web0template_2 is web0template {


    struct HTML {
        bytes head;
        bytes body;
    }

    web0template public immutable V1;

    constructor(address v1_){
        V1 = web0template(v1_);
    }

    //////////////////////////
    // HTML
    //////////////////////////


    function previewHtml(uint page_id_, web0plugins.PluginInput[] memory preview_, bool encode_, address web0_) public view override returns(string memory html_) {

        web0plugins.Plugin[] memory preview_plugins_ = new web0plugins.Plugin[](preview_.length);
        for (uint i = 0; i < preview_.length; i++){
            preview_plugins_[i] = web0plugins.Plugin(web0plugin(preview_[i].location).info().name, preview_[i].location, preview_[i].slot, preview_[i].params);
        }

        return _html(page_id_, encode_, preview_plugins_, web0(web0_));

    }

    function html(uint page_id_, bool encode_, address web0_) public view override returns(string memory html_){
        return _html(page_id_, encode_, new web0plugins.Plugin[](0), web0(web0_));
    }

    function _html(uint page_id_, bool encode_, web0plugins.Plugin[] memory preview_, web0 web0_) private view returns(string memory html_){

        web0plugins.Plugin[] memory plugins_ = web0_.plugins().list(page_id_);

        uint max_slots_ = web0_.MAX_SLOTS();

        bytes[] memory body_parts_ = new bytes[](max_slots_);
        bytes[] memory head_parts_ = new bytes[](max_slots_);

        uint i = 0;
        while(i < plugins_.length){
            if(plugins_[i].slot > 0 && plugins_[i].location != address(0)){
                head_parts_[plugins_[i].slot-1] = bytes(web0plugin(plugins_[i].location).head(page_id_, plugins_[i].params, false, address(web0_)));
                body_parts_[plugins_[i].slot-1] = bytes(web0plugin(plugins_[i].location).body(page_id_, plugins_[i].params, false, address(web0_)));
            }
            ++i;
        }
        
        i = 0;
        while(i < preview_.length){
            if(preview_[i].location != address(0)){
                head_parts_[preview_[i].slot-1] = bytes(web0plugin(preview_[i].location).head(page_id_, preview_[i].params, true, address(web0_)));
                body_parts_[preview_[i].slot-1] = bytes(web0plugin(preview_[i].location).body(page_id_, preview_[i].params, true, address(web0_)));
            }
            ++i;
        }

        HTML memory HTML_ = HTML(
            '',
            ''
        );

        
        i = 0;
        while(i < body_parts_.length) {
            HTML_.body = abi.encodePacked(HTML_.body, body_parts_[i]);
            HTML_.head = abi.encodePacked(HTML_.head, head_parts_[i]);
            ++i;
        }

        html_ = string(abi.encodePacked(
            '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta http-equiv="X-UA-Compatible" content="IE=edge"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>',
            web0_.getPageTitle(page_id_),
            '</title>',
            HTML_.head,
            '</head><body><main>',
            '<h1 id="page-title">',
            Esc.html(web0_.getPageTitle(page_id_)),
            '</h1>',
            HTML_.body,
            '</main></body></html>'
        ));

        if(encode_)
            html_ = string(abi.encodePacked('data:text/html;charset=UTF-8;base64,',Base64.encode(bytes(html_))));
        
        return html_;

    }


    

    /// @notice outputs the json of page_id_
    function json(uint page_id_, bool encode_, address web0_address_) public view override returns(string memory){
        return V1.json(page_id_, encode_, web0_address_);
    }



}