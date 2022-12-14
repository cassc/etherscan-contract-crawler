// SPDX-License-Identifier: MIT

/*
 * This is a part of fully-on-chain.sol, a npm package that allows developers
 * to create fully on-chain generative art.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import 'bytes-array.sol/BytesArray.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './IFontProvider.sol';
import './Path.sol';
import './Transform.sol';

library SVG {
  using Strings for uint;
  using BytesArray for bytes[];

  struct Attribute {
    string key;
    string value;
  }

  struct Element {
    bytes head;
    bytes tail;
    Attribute[] attrs;
  }

  function path(bytes memory _path) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<path d="', _path);
    elem.tail = bytes('"/>\n');
  }

  function char(IFontProvider _font, string memory _char) internal view returns (Element memory elem) {
    elem = SVG.path(Path.decode(_font.pathOf(_char)));
  }

  function textWidth(IFontProvider _font, string memory _str) internal view returns (uint x) {
    bytes memory data = bytes(_str);
    bytes memory ch = new bytes(1);
    for (uint i = 0; i < data.length; i++) {
      ch[0] = data[i];
      x += _font.widthOf(string(ch));
    }
  }

  function text(IFontProvider _font, string[2] memory _strs, uint _width) internal view returns (Element memory elem) {
    string[] memory strs = new string[](2);
    strs[0] = _strs[0];
    strs[1] = _strs[1];
    elem = text(_font, strs, _width);
  }

  function text(IFontProvider _font, string[3] memory _strs, uint _width) internal view returns (Element memory elem) {
    string[] memory strs = new string[](3);
    strs[0] = _strs[0];
    strs[1] = _strs[1];
    strs[2] = _strs[2];
    elem = text(_font, strs, _width);
  }

  function text(IFontProvider _font, string[4] memory _strs, uint _width) internal view returns (Element memory elem) {
    string[] memory strs = new string[](4);
    for (uint i = 0; i < _strs.length; i++) {
      strs[i] = _strs[i];
    }
    elem = text(_font, strs, _width);
  }

  function text(IFontProvider _font, string[5] memory _strs, uint _width) internal view returns (Element memory elem) {
    string[] memory strs = new string[](5);
    for (uint i = 0; i < _strs.length; i++) {
      strs[i] = _strs[i];
    }
    elem = text(_font, strs, _width);
  }

  function text(IFontProvider _font, string[6] memory _strs, uint _width) internal view returns (Element memory elem) {
    string[] memory strs = new string[](6);
    for (uint i = 0; i < _strs.length; i++) {
      strs[i] = _strs[i];
    }
    elem = text(_font, strs, _width);
  }

  function text(IFontProvider _font, string[7] memory _strs, uint _width) internal view returns (Element memory elem) {
    string[] memory strs = new string[](7);
    for (uint i = 0; i < _strs.length; i++) {
      strs[i] = _strs[i];
    }
    elem = text(_font, strs, _width);
  }

  function text(IFontProvider _font, string[] memory _strs, uint _width) internal view returns (Element memory elem) {
    uint height = _font.height();
    uint maxWidth = _width;
    Element[] memory elems = new Element[](_strs.length);
    for (uint i = 0; i < _strs.length; i++) {
      uint width = textWidth(_font, _strs[i]);
      if (width > maxWidth) {
        maxWidth = width;
      }
      elems[i] = transform(text(_font, _strs[i]), TX.translate(0, int(height * i)));
    }
    // extra group is necessary to let it transform
    elem = group(svg(transform(group(elems), TX.scale1000((1000 * _width) / maxWidth))));
  }

  function text(IFontProvider _font, string memory _str) internal view returns (Element memory elem) {
    bytes memory data = bytes(_str);
    bytes memory ch = new bytes(1);
    Element[] memory elems = new Element[](data.length);
    uint x;
    for (uint i = 0; i < data.length; i++) {
      ch[0] = data[i];
      elems[i] = SVG.path(Path.decode(_font.pathOf(string(ch))));
      if (x > 0) {
        elems[i] = transform(elems[i], string(abi.encodePacked('translate(', x.toString(), ' 0)')));
      }
      x += _font.widthOf(string(ch));
    }
    elem = group(elems);
  }

  function circle(int _cx, int _cy, int _radius) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked(
      '<circle cx="',
      uint(_cx).toString(),
      '" cy="',
      uint(_cy).toString(),
      '" r="',
      uint(_radius).toString()
    );
    elem.tail = '"/>\n';
  }

  function ellipse(int _cx, int _cy, int _rx, int _ry) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked(
      '<ellipse cx="',
      uint(_cx).toString(),
      '" cy="',
      uint(_cy).toString(),
      '" rx="',
      uint(_rx).toString(),
      '" ry="',
      uint(_ry).toString()
    );
    elem.tail = '"/>\n';
  }

  function rect(int _x, int _y, uint _width, uint _height) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked(
      '<rect x="',
      uint(_x).toString(),
      '" y="',
      uint(_y).toString(),
      '" width="',
      _width.toString(),
      '" height="',
      _height.toString()
    );
    elem.tail = '"/>\n';
  }

  function rect() internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<rect width="100%" height="100%');
    elem.tail = '"/>\n';
  }

  function stop(uint ratio) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<stop offset="', ratio.toString(), '%');
    elem.tail = '"/>\n';
  }

  function use(string memory _id) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<use href="#', _id);
    elem.tail = '"/>\n';
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function packed(Element[8] memory _elements) internal pure returns (bytes memory output) {
    bytes[] memory svgs = new bytes[](8);
    svgs[0] = svg(_elements[0]);
    svgs[1] = svg(_elements[1]);
    svgs[2] = svg(_elements[2]);
    svgs[3] = svg(_elements[3]);
    svgs[4] = svg(_elements[4]);
    svgs[5] = svg(_elements[5]);
    svgs[6] = svg(_elements[6]);
    svgs[7] = svg(_elements[7]);
    output = svgs.packed();
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function packed(Element[4] memory _elements) internal pure returns (bytes memory output) {
    bytes[] memory svgs = new bytes[](4);
    svgs[0] = svg(_elements[0]);
    svgs[1] = svg(_elements[1]);
    svgs[2] = svg(_elements[2]);
    svgs[3] = svg(_elements[3]);
    output = svgs.packed();
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function packed(Element[3] memory _elements) internal pure returns (bytes memory output) {
    bytes[] memory svgs = new bytes[](3);
    svgs[0] = svg(_elements[0]);
    svgs[1] = svg(_elements[1]);
    svgs[2] = svg(_elements[2]);
    output = svgs.packed();
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function packed(Element[2] memory _elements) internal pure returns (bytes memory output) {
    bytes[] memory svgs = new bytes[](2);
    svgs[0] = svg(_elements[0]);
    svgs[1] = svg(_elements[1]);
    output = svgs.packed();
  }

  function packed(Element[] memory _elements) internal pure returns (bytes memory output) {
    bytes[] memory svgs = new bytes[](_elements.length);
    for (uint i = 0; i < _elements.length; i++) {
      svgs[i] = svg(_elements[i]);
    }
    output = svgs.packed();
  }

  function pattern(
    string memory _id,
    string memory _viewbox,
    string memory _width,
    string memory _height,
    bytes memory _elements
  ) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked(
      '<pattern id="',
      _id,
      '" viewBox="',
      _viewbox,
      '" width="',
      _width,
      '" height="',
      _height
    );
    elem.tail = abi.encodePacked('">', _elements, '</pattern>\n');
  }

  function pattern(
    string memory _id,
    string memory _viewbox,
    string memory _width,
    string memory _height,
    Element memory _element
  ) internal pure returns (Element memory elem) {
    elem = pattern(_id, _viewbox, _width, _height, svg(_element));
  }

  function filter(string memory _id, bytes memory _elements) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<filter id="', _id);
    elem.tail = abi.encodePacked('">', _elements, '</filter>\n');
  }

  function filter(string memory _id, Element memory _element) internal pure returns (Element memory elem) {
    elem = filter(_id, svg(_element));
  }

  function feGaussianBlur(string memory _src, string memory _stdDeviation) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<feGaussianBlur in="', _src, '" stdDeviation="', _stdDeviation);
    elem.tail = '" />';
  }

  /*
      '  <feOffset result="offOut" in="SourceAlpha" dx="24" dy="32" />\n'
      '  <feGaussianBlur result="blurOut" in="offOut" stdDeviation="16" />\n'
      '  <feBlend in="SourceGraphic" in2="blurOut" mode="normal" />\n'
  */
  function feOffset(
    string memory _src,
    string memory _dx,
    string memory _dy
  ) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<feOffset in="', _src, '" dx="', _dx, '" dy="', _dy);
    elem.tail = '" />';
  }

  function feBlend(
    string memory _src,
    string memory _src2,
    string memory _mode
  ) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<feBlend in="', _src, '" in2="', _src2, '" mode="', _mode);
    elem.tail = '" />';
  }

  function linearGradient(string memory _id, bytes memory _elements) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<linearGradient id="', _id);
    elem.tail = abi.encodePacked('">', _elements, '</linearGradient>\n');
  }

  function linearGradient(string memory _id, Element memory _element) internal pure returns (Element memory elem) {
    elem = linearGradient(_id, svg(_element));
  }

  function radialGradient(string memory _id, bytes memory _elements) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<radialGradient id="', _id);
    elem.tail = abi.encodePacked('">', _elements, '</radialGradient>\n');
  }

  function radialGradient(string memory _id, Element memory _element) internal pure returns (Element memory elem) {
    elem = radialGradient(_id, svg(_element));
  }

  function group(bytes memory _elements) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<g x_x="x'); // HACK: dummy header for trailing '"'
    elem.tail = abi.encodePacked('">', _elements, '</g>\n');
  }

  function group(Element memory _element) internal pure returns (Element memory elem) {
    elem = group(svg(_element));
  }

  function group(Element[] memory _elements) internal pure returns (Element memory elem) {
    elem = group(packed(_elements));
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function group(Element[2] memory _elements) internal pure returns (Element memory elem) {
    elem = group(packed(_elements));
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function group(Element[3] memory _elements) internal pure returns (Element memory elem) {
    elem = group(packed(_elements));
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function group(Element[4] memory _elements) internal pure returns (Element memory elem) {
    elem = group(packed(_elements));
  }

  function group(Element[8] memory _elements) internal pure returns (Element memory elem) {
    elem = group(packed(_elements));
  }

  function element(bytes memory _body) internal pure returns (Element memory elem) {
    elem.tail = _body;
  }

  function list(Element[] memory _elements) internal pure returns (Element memory elem) {
    elem.tail = packed(_elements);
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function list(Element[2] memory _elements) internal pure returns (Element memory elem) {
    elem.tail = packed(_elements);
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function list(Element[3] memory _elements) internal pure returns (Element memory elem) {
    elem.tail = packed(_elements);
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function list(Element[4] memory _elements) internal pure returns (Element memory elem) {
    elem.tail = packed(_elements);
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function list(Element[8] memory _elements) internal pure returns (Element memory elem) {
    elem.tail = packed(_elements);
  }

  function mask(string memory _id, bytes memory _elements) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<mask id="', _id, ''); // HACK: dummy header for trailing '"'
    elem.tail = abi.encodePacked(
      '">'
      '<rect x="0" y="0" width="100%" height="100%" fill="black"/>'
      '<g fill="white">',
      _elements,
      '</g>'
      '</mask>\n'
    );
  }

  function mask(string memory _id, Element memory _element) internal pure returns (Element memory elem) {
    elem = mask(_id, svg(_element));
  }

  function stencil(bytes memory _elements) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<mask x_x="x'); // HACK: dummy header for trailing '"'
    elem.tail = abi.encodePacked(
      '">'
      '<rect x="0" y="0" width="100%" height="100%" fill="white"/>'
      '<g fill="black">',
      _elements,
      '</g>'
      '</mask>\n'
    );
  }

  function stencil(Element memory _element) internal pure returns (Element memory elem) {
    elem = stencil(svg(_element));
  }

  function _append(Element memory _element, Attribute memory _attr) internal pure returns (Element memory elem) {
    elem.head = _element.head;
    elem.tail = _element.tail;
    elem.attrs = new Attribute[](_element.attrs.length + 1);
    for (uint i = 0; i < _element.attrs.length; i++) {
      elem.attrs[i] = _element.attrs[i];
    }
    elem.attrs[_element.attrs.length] = _attr;
  }

  function _append2(
    Element memory _element,
    Attribute memory _attr,
    Attribute memory _attr2
  ) internal pure returns (Element memory elem) {
    elem.head = _element.head;
    elem.tail = _element.tail;
    elem.attrs = new Attribute[](_element.attrs.length + 2);
    for (uint i = 0; i < _element.attrs.length; i++) {
      elem.attrs[i] = _element.attrs[i];
    }
    elem.attrs[_element.attrs.length] = _attr;
    elem.attrs[_element.attrs.length + 1] = _attr2;
  }

  function id(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('id', _value));
  }

  function fill(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('fill', _value));
  }

  function opacity(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('opacity', _value));
  }

  function stopColor(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('stop-color', _value));
  }

  function x1(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('x1', _value));
  }

  function x2(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('x2', _value));
  }

  function y1(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('y1', _value));
  }

  function y2(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('y2', _value));
  }

  function cx(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('cy', _value));
  }

  function cy(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('cy', _value));
  }

  function r(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('r', _value));
  }

  function fx(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('fx', _value));
  }

  function fy(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('fy', _value));
  }

  function result(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('result', _value));
  }

  function fillRef(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('fill', string(abi.encodePacked('url(#', _value, ')'))));
  }

  function filter(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('filter', string(abi.encodePacked('url(#', _value, ')'))));
  }

  function style(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('style', _value));
  }

  function transform(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('transform', _value));
  }

  function mask(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('mask', string(abi.encodePacked('url(#', _value, ')'))));
  }

  function stroke(
    Element memory _element,
    string memory _color,
    uint _width
  ) internal pure returns (Element memory elem) {
    elem = _append2(_element, Attribute('stroke', _color), Attribute('stroke-width', _width.toString()));
  }

  function svg(Element memory _element) internal pure returns (bytes memory output) {
    if (_element.head.length > 0) {
      output = _element.head;
      for (uint i = 0; i < _element.attrs.length; i++) {
        Attribute memory attr = _element.attrs[i];
        output = abi.encodePacked(output, '" ', attr.key, '="', attr.value);
      }
    } else {
      require(_element.attrs.length == 0, 'Attributes on list');
    }
    output = abi.encodePacked(output, _element.tail);
  }

  function document(
    string memory _viewBox,
    bytes memory _defs,
    bytes memory _body
  ) internal pure returns (string memory) {
    bytes memory output = abi.encodePacked(
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<svg viewBox="',
      _viewBox,
      '"'
      ' xmlns="http://www.w3.org/2000/svg">\n'
    );
    if (_defs.length > 0) {
      output = abi.encodePacked(output, '<defs>\n', _defs, '</defs>\n');
    }
    output = abi.encodePacked(output, _body, '</svg>\n');
    return string(output);
  }
}