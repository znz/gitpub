# -*- mode: ruby; coding: utf-8 -*-
require 'gitpub'
run GitPub.new('linux-2.6/.git', /\Av2\.6\.\d+\z/)
