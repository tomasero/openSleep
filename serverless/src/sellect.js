/**
 * @file sellect.js is micro-library.
 * Scaffolded with generator-microjs
 * @author Lidia Freitas <lidiafreitas.me@gmail.com>
 */

(function () {

    this.sellect = function (selector, options) {
        /*jslint newcap:true */
        return new _Sellect(selector, options);
    };

    this._Sellect = function (selector, options) {
        this.container = document.createElement('div');
        this.originListHTML = document.createElement('div');
        this.destinationListHTML = document.createElement('div');
        this.arrow = document.createElement('i');

        var defaults = {
            element: typeof(selector) === 'object' ? selector : document.querySelector(selector),
            originList: [],
            destinationList: []
        };

        if (arguments[0] && typeof arguments[1] === 'object') {
            this.options = extendDefaults(defaults, arguments[1]);
        }
    };

    function createHTML () {
        var self = this;

        if (self.options) {
            self.options.originList.forEach(function (item) {
                createListsHTML(self.originListHTML, item);
            });

            self.options.destinationList.forEach(function (item) {
                createListsHTML(self.destinationListHTML, item);
            });

            self.options.element.parentNode.insertBefore(self.container, self.options.element);

            self.container.appendChild(self.destinationListHTML);
            self.container.appendChild(self.options.element);
            self.container.appendChild(self.originListHTML);
            self.container.appendChild(self.arrow);
        }
    }

    function createListsHTML(list, item) {
        var listItem = document.createElement('span');
        var listIcon = document.createElement('i');
        listItem.classList.add('sellect-trigger', 'sellect-item');
        listIcon.classList.add('fa', 'fa-times', 'sellect-close-icon');

        listItem.innerHTML = item;
        listItem.appendChild(listIcon);
        list.appendChild(listItem);
    }

    function initializeEvents () {
        var self = this;

        if (self.options) {
            self.originListHTML.addEventListener('click', function () {
                swapItemDOM.call(self, event.target, self.destinationListHTML);
            }, false);

            self.destinationListHTML.addEventListener('click', function () {
                swapItemDOM.call(self, event.target, self.originListHTML);
            }, false);

            self.container.addEventListener('click', function () {
                openOriginList.call(self);
            }, false);

            self.arrow.addEventListener('click', function () {
                toggleOriginList.call(self);
            }, false);

            self.options.element.addEventListener('keyup', function () {
                var key = event.keyCode || event.charCode;

                switch (key){
                    case 40:
                        if(self.originListHTML.childNodes.length > 0){
                            selectionDown.call(self);
                            scrollTop.call(self);
                        }
                        break;

                    case 38:
                        if(self.originListHTML.childNodes.length > 0) {
                            selectionUp.call(self);
                            scrollBottom.call(self);
                        }
                        break;

                    case 13:
                        selectItemOriginList.call(self);
                        break;

                    default:
                        filterOriginList.call(self);
                        break;
                }

            }, false);

            self.options.element.addEventListener('keydown', function () {
                captureEmpty.call(self);
            }, false);

            self.options.element.addEventListener('focus', function () {
                openOriginList.call(self);
            }, false);

            window.addEventListener('click', function () {
                closeOriginList.call(self);
            }, false);
        }
    }

    function swapItemDOM(trigger, list) {
        var self = this;
        var item;
        if(!trigger) return;

        item = trigger.classList.contains('sellect-trigger') ? trigger : trigger.parentNode;

        event.stopPropagation();

        if (!item || item.className.indexOf('sellected-list') > -1 || item.className.indexOf('sellect-list') > -1) {
            return;
        }

        item.parentNode.removeChild(item);
        list.appendChild(item);
        item.classList.remove('active');

        self.options.element.value = '';
        self.options.element.focus();
        createEventListener.call(self, 'keyup');

        self.options.originList = [];
        self.options.destinationList = [];

        self.options.originList = self.getUnselected();
        self.options.destinationList  = self.getSelected();

        if(self.options.onInsert)
            self.options.onInsert(event, item);

        if(self.options.onRemove)
            self.options.onRemove(event,item);
    }

    function filterOriginList() {
        var self = this;
        var string = event.target.value;
        var items = self.originListHTML.childNodes;

        items.forEach(function (item) {
            if (item.innerText.indexOf(string) !== -1) {
                item.style.display = 'inherit';
            }
            else {
                item.style.display = 'none';
            }
        });
    }

    function captureEmpty() {
        var self = this;
        var key = event.keyCode || event.charCode;
        var string = event.target.value;

        if (key === 8 && string === '' && self.destinationListHTML.childNodes.length > 0) {
            var lastItem = self.destinationListHTML.lastElementChild;
            lastItem.click();
        }
    }

    function selectionUp() {
        var self = this;
        var selectedItem = self.originListHTML.getElementsByClassName('active')[0];
        var prevItem;

        if (!selectedItem || !selectedItem.previousElementSibling) {
            return;
        }

        prevItem = getOriginListVisibleItem(selectedItem.previousElementSibling);

        if(prevItem){
            prevItem .classList.add('active');
            selectedItem.classList.remove('active');
        }
    }

    function selectionDown() {
        var self = this;
        var selectedItem = self.originListHTML.getElementsByClassName('active')[0];
        var nextItem;

        if (!selectedItem) {
            nextItem = getOriginListVisibleItem(self.originListHTML.childNodes[0], 'down');

            if(nextItem){
                nextItem.classList.add('active');
            }

            return;
        }

        if (!selectedItem.nextElementSibling) return;

        nextItem = getOriginListVisibleItem(selectedItem.nextElementSibling, 'down');

        if(nextItem){
            nextItem.classList.add('active');
            selectedItem.classList.remove('active');
        }
    }

    function scrollTop () {
        var self = this;
        var selectedItem = self.originListHTML.getElementsByClassName('active')[0];

        if (!selectedItem) return;

        var itemPositionTop = selectedItem.offsetTop;

        if(itemPositionTop >= self.originListHTML.clientHeight + selectedItem.clientHeight){
            self.originListHTML.scrollTop = self.originListHTML.scrollTop + selectedItem.clientHeight;
            return true;
        }
    }

    function scrollBottom (){
        var self = this;
        var selectedItem = self.originListHTML.getElementsByClassName('active')[0];

        if (!selectedItem) return;

        var itemPositionTop = selectedItem.offsetTop;

        if(itemPositionTop <= (self.originListHTML.scrollHeight - self.originListHTML.clientHeight) + selectedItem.clientHeight){
            self.originListHTML.scrollTop = self.originListHTML.scrollTop - selectedItem.clientHeight;
            return true;
        }
    }

    function getOriginListVisibleItem(selectCandidate, direction) {
        if(direction === 'down'){
            while (selectCandidate.offsetParent === null && selectCandidate.nextElementSibling){
                selectCandidate = selectCandidate.nextElementSibling;
            }
        }
        else{
            while (selectCandidate.offsetParent === null && selectCandidate.previousElementSibling){
                selectCandidate = selectCandidate.previousElementSibling;
            }
        }

        return selectCandidate.offsetParent !== null ? selectCandidate : false;

    }

    function selectItemOriginList() {
        var self = this;

        var selectedItem = self.originListHTML.getElementsByClassName('active')[0];

        swapItemDOM.call(self, selectedItem, self.destinationListHTML);
    }

    function createEventListener(eventType) {
        var self = this;
        var customEvent = document.createEvent('Event');
        customEvent.initEvent(eventType);
        self.options.element.dispatchEvent(customEvent);
    }

    function openOriginList() {
        var self = this;
        event.stopPropagation();

        if(!self.originListHTML.classList.contains('open')){
            self.options.element.focus();
            self.originListHTML.classList.add('open');
        }
    }

    function closeOriginList() {
        var self = this;
        event.stopPropagation();

        if(self.originListHTML.classList.contains('open')){
            self.originListHTML.classList.remove('open');
        }
    }

    function toggleOriginList() {
        var self = this;
        event.stopPropagation();

        if(!self.originListHTML.classList.contains('open')){
            self.originListHTML.classList.add('open');
        }else{
            self.originListHTML.classList.remove('open');
        }
    }

    function extendDefaults(source, properties) {
        var property;
        for (property in properties) {
            if (properties.hasOwnProperty(property)) {
                source[property] = properties[property];
            }
        }
        return source;
    }

    _Sellect.prototype.init = function () {
        var self = this;

        if (self.options) {
            self.options.destinationList.forEach(function (itemOuter) {
                self.options.originList = self.options.originList.filter(function (itemInner) {
                    return itemInner !== itemOuter;
                });
            });

            self.options.element.setAttribute('class', 'sellect-element');
            self.container.setAttribute('class', 'sellect-container');
            self.originListHTML.setAttribute('class', 'sellect-origin-list');
            self.destinationListHTML.setAttribute('class', 'sellect-destination-list');
            self.arrow.setAttribute('class', 'fa fa-chevron-down sellect-arrow-icon');
        }

        createHTML.call(self);
        initializeEvents.call(self);
    };

    _Sellect.prototype.getSelected = function () {
        var self = this;
        self.options.destinationList = [];

        for(var i = 0; i < self.destinationListHTML.childNodes.length; i++){
            self.options.destinationList.push(self.destinationListHTML.childNodes[i].textContent);
        }

        return self.options.destinationList;
    };

    _Sellect.prototype.getUnselected = function () {
        var self = this;
        self.options.originList = [];

        for(var i = 0; i < self.originListHTML.childNodes.length; i++){
            self.options.originList.push(self.originListHTML.childNodes[i].textContent);
        }

        return self.options.originList;
    };
})();
